#!/usr/bin/env bash
# Wait for the genuine fallback Quality Gate for this head before Claude Review.
set -euo pipefail

REPO="${1:-${GITHUB_REPOSITORY:-}}"
HEAD_SHA="${2:-${GITHUB_SHA:-}}"
MAX_WAIT_TIME="${MAX_WAIT_TIME:-4500}"
POLL_INTERVAL="${POLL_INTERVAL:-30}"
ELAPSED_TIME=0
if [ -z "$REPO" ] || [ -z "$HEAD_SHA" ]; then
  echo "Usage: $0 <owner/repo> <head-sha>" >&2
  exit 2
fi
write_ci_result() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "ci_passed=$1" >> "$GITHUB_OUTPUT"; fi
}

# GH pagination must account for every response row before a success can be trusted.
complete_pages() {
  jq -ce --arg key "$1" '
    if type != "array" or length == 0 then error("Invalid pages") else . end
    | if any(.[]; type != "object" or (.[$key] | type) != "array" or
        (.total_count | type) != "number" or .total_count < 0 or .total_count != (.total_count | floor))
      then error("Invalid page schema") else . end
    | .[0].total_count as $total
    | if any(.[]; .total_count != $total) then error("Inconsistent page counts") else . end
    | [.[].[$key][]]
    | if length != $total or any(.[]; type != "object" or (.id | type) != "number" or
        (.head_sha | type) != "string" or (.status | type) != "string") or
        ([.[].id] | unique | length) != $total then error("Incomplete or duplicate rows") else . end'
}

# Workflow identity and attempt-scoped jobs prevent stale or same-name checks passing.
fetch_gate_state() {
  local workflow_name="$1" workflow workflow_id pages selected run_id attempt current jobs gate receipt
  workflow="$(gh api "repos/$REPO/actions/workflows/$workflow_name")" || return 1
  workflow_id="$(jq -er --arg path ".github/workflows/$workflow_name" 'select(.state == "active" and .path == $path) | .id | select(type == "number" and . > 0)' <<< "$workflow")" || return 1
  pages="$(gh api --paginate --slurp "repos/$REPO/actions/workflows/$workflow_id/runs?head_sha=$HEAD_SHA&per_page=100")" || return 1
  pages="$(complete_pages workflow_runs <<< "$pages")" || return 1
  selected="$(jq -cer --arg sha "$HEAD_SHA" --argjson id "$workflow_id" '
    if any(.[]; .head_sha != $sha or .workflow_id != $id) then error("Unexpected run identity") else . end
    | if any(.[]; (.created_at | type) != "string" or (.run_number | type) != "number" or (.id | type) != "number" or (.run_attempt | type) != "number") then error("Invalid run metadata") else . end
    | sort_by([(.created_at | fromdateiso8601), .run_number, .id, .run_attempt]) | last // {}' <<< "$pages")" || return 1
  run_id="$(jq -r '.id // empty' <<< "$selected")"
  if [ -z "$run_id" ]; then echo '{"state":"pending"}'; return; fi
  current="$(gh api "repos/$REPO/actions/runs/$run_id")" || return 1
  attempt="$(jq -er --arg sha "$HEAD_SHA" --argjson wid "$workflow_id" --argjson selected "$selected" '
    select(.id == $selected.id and .workflow_id == $wid and .head_sha == $sha and
      (.run_attempt | type) == "number" and .run_attempt >= $selected.run_attempt and
      (.check_suite_id | type) == "number" and .check_suite_id > 0) | .run_attempt' <<< "$current")" || return 1
  case "$(jq -r '.status' <<< "$current")" in
    queued|in_progress|waiting|pending|requested) echo '{"state":"pending"}'; return ;;
    completed) ;;
    *) return 1 ;;
  esac
  if [ "$(jq -r '.conclusion' <<< "$current")" != success ]; then echo '{"state":"failure"}'; return; fi
  receipt="$(jq -c '{state:"success", run_id:.id, workflow_id, run_attempt, suite_id:.check_suite_id}' <<< "$current")"
  if [ "$workflow_name" = ci.yml ]; then echo "$receipt"; return; fi
  jobs="$(gh api --paginate --slurp "repos/$REPO/actions/runs/$run_id/attempts/$attempt/jobs?per_page=100")" || return 1
  jobs="$(complete_pages jobs <<< "$jobs")" || return 1
  gate="$(jq -ce --arg sha "$HEAD_SHA" --arg prefix "https://api.github.com/repos/$REPO/check-runs/" --argjson run "$current" '
    [.[] | select(.name == "Quality Gate")]
    | if length == 0 then {state:"pending"} elif length != 1 then error("Ambiguous gate") else .[0]
      | if .head_sha != $sha or .run_id != $run.id or .run_attempt != $run.run_attempt or
          (.check_run_url | type) != "string" or (.check_run_url | startswith($prefix) | not)
        then error("Invalid job identity") else . end
      | (.check_run_url | ltrimstr($prefix)) as $check
      | if ($check | test("^[0-9]+$") | not) then error("Invalid check identity") else . end
      | {check_id:($check | tonumber), state:(if .status == "completed" then
          (if .conclusion == "success" then "success" else "failure" end)
        elif (.status == "queued" or .status == "in_progress" or .status == "waiting") then "pending" else "failure" end)} end' <<< "$jobs")" || return 1
  jq -cn --argjson receipt "$receipt" --argjson gate "$gate" '$receipt + $gate'
}

echo "Waiting for CI to complete for $REPO (SHA: $HEAD_SHA)"
while [ "$ELAPSED_TIME" -lt "$MAX_WAIT_TIME" ]; do
  GATE_STATE=success
  RECEIPTS='[]'
  # A later ci.yml rerun invalidates an earlier successful fallback receipt.
  for WORKFLOW_NAME in ci.yml quality-gate-fallback.yml; do
    if ! CURRENT_STATE="$(fetch_gate_state "$WORKFLOW_NAME")"; then
      write_ci_result false
      echo 'Could not verify current CI (API or metadata error)'
      exit 0
    fi
    RECEIPTS="$(jq -c --argjson receipt "$CURRENT_STATE" '. + [$receipt]' <<< "$RECEIPTS")"
    CURRENT_STATE="$(jq -r .state <<< "$CURRENT_STATE")"
    if [ "$CURRENT_STATE" != success ]; then
      GATE_STATE="$CURRENT_STATE"
      if [ "$CURRENT_STATE" = failure ]; then break; fi
    fi
  done
  if [ "$GATE_STATE" = failure ]; then
    write_ci_result false
    echo 'Quality Gate failed'
    exit 0
  fi
  if [ "$GATE_STATE" = success ]; then
    # Preserve completed-failure rejection without requiring optional pending checks.
    if ! CHECK_RUNS="$(gh api --paginate --slurp "repos/$REPO/commits/$HEAD_SHA/check-runs?per_page=100")"; then
      write_ci_result false
      exit 0
    fi
    if ! CHECK_RUNS="$(complete_pages check_runs <<< "$CHECK_RUNS")"; then
      write_ci_result false
      exit 0
    fi
    # Reconcile after the check read: API snapshots are not atomic across reruns.
    if ! RUNS="$(gh api --paginate --slurp "repos/$REPO/actions/runs?head_sha=$HEAD_SHA&per_page=100")" ||
       ! RUNS="$(complete_pages workflow_runs <<< "$RUNS")"; then
      write_ci_result false
      exit 0
    fi
    if ! FINAL_STATE="$(jq -er --arg sha "$HEAD_SHA" --argjson runs "$RUNS" --argjson receipts "$RECEIPTS" '
      def positive: type == "number" and . > 0 and . == floor;
      def status: IN("completed", "queued", "in_progress", "waiting", "pending", "requested");
      if any($runs[]; .head_sha != $sha or ([.id,.workflow_id,.check_suite_id,.run_attempt,.run_number] | all(.[]; positive) | not)
          or (.created_at | type) != "string" or (.status | status | not) or (.status == "completed" and
            (.conclusion | IN("success","failure","neutral","cancelled","skipped","timed_out","action_required","stale","startup_failure") | not))) or
          ([$runs[].check_suite_id] | unique | length) != ($runs | length)
        then error("Invalid run inventory") else . end
      | ($runs | group_by(.workflow_id) | map(max_by([(.created_at | fromdateiso8601),.run_number,.id,.run_attempt]))) as $latest
      | [$runs[] as $run | select(any($latest[]; .workflow_id == $run.workflow_id and .id != $run.id)) | $run.check_suite_id] as $obsolete
      | if any(.[]; .head_sha != $sha or (.id | positive | not) or (.name | type) != "string" or (.app.id | positive | not) or
          (.app.slug | type) != "string" or (.check_suite.id | positive | not) or (.status | status | not) or
          (.app.slug == "github-actions" and (.check_suite.id as $suite | any($runs[]; .check_suite_id == $suite) | not)))
        then error("Invalid check identity") else . end
      | [.[] | select(.name != "check-ci-status" and .name != "claude-review")
          | select(.check_suite.id as $suite | $obsolete | index($suite) | not)]
      | group_by([.app.id,.check_suite.id,.name]) | map(max_by(.id)) as $checks
      | if any($latest[]; .status == "completed" and (.conclusion | IN("success","skipped","neutral") | not)) or
          any($checks[]; .status == "completed" and (.conclusion | IN("success","skipped","neutral") | not)) then "failure"
        elif any($receipts[]; . as $receipt | [$latest[] | select(.workflow_id == $receipt.workflow_id)] as $current
          | ($current | length) != 1 or $current[0].id != .run_id or $current[0].run_attempt != .run_attempt or
            $current[0].check_suite_id != .suite_id or $current[0].status != "completed" or $current[0].conclusion != "success" or
            any($checks[]; .check_suite.id == $receipt.suite_id and .status != "completed") or
            (has("check_id") and (any($checks[]; .id == $receipt.check_id and .check_suite.id == $receipt.suite_id and
              .name == "Quality Gate" and .app.slug == "github-actions" and .status == "completed" and .conclusion == "success") | not)))
          then "pending" else "success" end' <<< "$CHECK_RUNS")"; then
      write_ci_result false
      echo 'Some CI checks failed or could not be read'
      exit 0
    fi
    if [ "$FINAL_STATE" != pending ]; then
      write_ci_result "$([ "$FINAL_STATE" = success ] && echo true || echo false)"
      echo "CI verification: $FINAL_STATE"
      exit 0
    fi
  fi
  sleep "$POLL_INTERVAL"
  ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
done
write_ci_result false
echo "Timeout: CI did not complete within ${MAX_WAIT_TIME}s"
