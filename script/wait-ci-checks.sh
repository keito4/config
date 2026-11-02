#!/usr/bin/env bash
# Wait for the genuine fallback Quality Gate for this head before Claude Review.
set -euo pipefail

REPO="${1:-${GITHUB_REPOSITORY:-}}"
HEAD_SHA="${2:-${GITHUB_SHA:-}}"
MAX_WAIT_TIME="${MAX_WAIT_TIME:-900}"
POLL_INTERVAL="${POLL_INTERVAL:-30}"
ELAPSED_TIME=0
if [ -z "$REPO" ] || [ -z "$HEAD_SHA" ]; then
  echo "Usage: $0 <owner/repo> <head-sha>" >&2
  exit 2
fi
write_ci_result() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "ci_passed=$1" >> "$GITHUB_OUTPUT"; fi
}

# Workflow identity and attempt-scoped jobs prevent stale or same-name checks passing.
fetch_gate_state() {
  local workflow workflow_id pages selected run_id attempt current jobs
  workflow="$(gh api "repos/$REPO/actions/workflows/quality-gate-fallback.yml")" || return 1
  workflow_id="$(jq -er 'select(.state == "active" and .path == ".github/workflows/quality-gate-fallback.yml") | .id | select(type == "number" and . > 0)' <<< "$workflow")" || return 1
  pages="$(gh api --paginate --slurp "repos/$REPO/actions/workflows/$workflow_id/runs?head_sha=$HEAD_SHA&per_page=100")" || return 1
  selected="$(jq -cer --arg sha "$HEAD_SHA" --argjson id "$workflow_id" '
    [.[].workflow_runs[] | select(.head_sha == $sha and .workflow_id == $id)]
    | if any(.[]; (.created_at | type) != "string" or (.run_number | type) != "number" or (.id | type) != "number" or (.run_attempt | type) != "number") then error("Invalid run metadata") else . end
    | sort_by([(.created_at | fromdateiso8601), .run_number, .id, .run_attempt]) | last // {}' <<< "$pages")" || return 1
  run_id="$(jq -r '.id // empty' <<< "$selected")"
  if [ -z "$run_id" ]; then echo pending; return; fi
  current="$(gh api "repos/$REPO/actions/runs/$run_id")" || return 1
  attempt="$(jq -er --arg sha "$HEAD_SHA" --argjson wid "$workflow_id" --argjson selected "$selected" '
    select(.id == $selected.id and .workflow_id == $wid and .head_sha == $sha and
      (.run_attempt | type) == "number" and .run_attempt >= $selected.run_attempt) | .run_attempt' <<< "$current")" || return 1
  case "$(jq -r '.status' <<< "$current")" in
    queued|in_progress|waiting|pending|requested) echo pending; return ;;
    completed) ;;
    *) return 1 ;;
  esac
  if [ "$(jq -r '.conclusion' <<< "$current")" != success ]; then echo failure; return; fi
  jobs="$(gh api --paginate --slurp "repos/$REPO/actions/runs/$run_id/attempts/$attempt/jobs?per_page=100")" || return 1
  jq -r --arg sha "$HEAD_SHA" '
    [.[].jobs[] | select(.name == "Quality Gate" and .head_sha == $sha)] | max_by(.id)
    | if . == null then "pending"
      elif .status == "completed" then (if .conclusion == "success" then "success" else "failure" end)
      elif (.status == "queued" or .status == "in_progress" or .status == "waiting") then "pending"
      else "failure" end' <<< "$jobs"
}

echo "Waiting for CI to complete for $REPO (SHA: $HEAD_SHA)"
while [ "$ELAPSED_TIME" -lt "$MAX_WAIT_TIME" ]; do
  if ! GATE_STATE="$(fetch_gate_state)"; then
    write_ci_result false
    echo 'Could not verify the current Quality Gate (API or metadata error)'
    exit 0
  fi
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
    if ! jq -e --arg sha "$HEAD_SHA" '
      [.[].check_runs[] | select(.head_sha == $sha and .name != "check-ci-status" and .name != "claude-review")]
      | group_by([.app.id, .name]) | map(max_by(.id))
      | all(.[]; .status != "completed" or .conclusion == "success" or .conclusion == "skipped" or .conclusion == "neutral")' <<< "$CHECK_RUNS" >/dev/null; then
      write_ci_result false
      echo 'Some CI checks failed or could not be read'
      exit 0
    fi
    write_ci_result true
    echo 'All CI checks passed'
    exit 0
  fi
  sleep "$POLL_INTERVAL"
  ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
done
write_ci_result false
echo "Timeout: CI did not complete within ${MAX_WAIT_TIME}s"
