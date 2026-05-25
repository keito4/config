#!/usr/bin/env bash
# Wait for required CI checks before running Claude Code Review.

set -euo pipefail

REPO="${1:-${GITHUB_REPOSITORY:-}}"
HEAD_SHA="${2:-${GITHUB_SHA:-}}"
MAX_WAIT_TIME="${MAX_WAIT_TIME:-900}"
POLL_INTERVAL="${POLL_INTERVAL:-30}"
QUALITY_GATE_MISSING_GRACE="${QUALITY_GATE_MISSING_GRACE:-120}"
ELAPSED_TIME=0

if [ -z "$REPO" ] || [ -z "$HEAD_SHA" ]; then
  echo "Usage: $0 <owner/repo> <head-sha>" >&2
  exit 2
fi

write_ci_result() {
  local value="$1"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "ci_passed=$value" >> "$GITHUB_OUTPUT"
  fi
}

fetch_check_runs() {
  if [ -n "${CHECK_RUNS_JSON:-}" ]; then
    echo "$CHECK_RUNS_JSON" | jq -c '.[] | {name, status, conclusion}'
    return
  fi

  gh api "repos/$REPO/commits/$HEAD_SHA/check-runs" \
    --jq '.check_runs[] | select(.name != "check-ci-status" and .name != "claude-review") | {name, status, conclusion}'
}

echo "Waiting for CI to complete for $REPO (SHA: $HEAD_SHA)"

while [ "$ELAPSED_TIME" -lt "$MAX_WAIT_TIME" ]; do
  echo "Elapsed time: ${ELAPSED_TIME}s / ${MAX_WAIT_TIME}s"

  CHECK_RUNS="$(fetch_check_runs)"

  echo "Check Runs:"
  echo "$CHECK_RUNS" | jq -r '"\(.name): \(.status) - \(.conclusion)"'

  QUALITY_GATE="$(echo "$CHECK_RUNS" | jq -r 'select(.name == "Quality Gate")')"

  if [ -z "$QUALITY_GATE" ]; then
    if [ "$ELAPSED_TIME" -ge "$QUALITY_GATE_MISSING_GRACE" ]; then
      DETECT_CHANGES="$(echo "$CHECK_RUNS" | jq -r 'select(.name == "Detect Changes")')"
      if [ -z "$DETECT_CHANGES" ]; then
        write_ci_result true
        echo "CI workflow skipped by path filters; proceeding with Claude Code Review."
        exit 0
      fi
    fi

    echo "Quality Gate check has not started yet, waiting..."
    sleep "$POLL_INTERVAL"
    ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
    continue
  fi

  if echo "$QUALITY_GATE" | jq -e 'select(.status != "completed")' >/dev/null; then
    echo "Quality Gate is still running, waiting..."
    echo "$QUALITY_GATE" | jq -r '"\(.name): \(.status) - \(.conclusion)"'
    sleep "$POLL_INTERVAL"
    ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
    continue
  fi

  if echo "$QUALITY_GATE" | jq -e 'select(.conclusion != "success")' >/dev/null; then
    write_ci_result false
    echo "Quality Gate failed:"
    echo "$QUALITY_GATE" | jq -r 'select(.conclusion != "success") | "\(.name): \(.conclusion)"'
    exit 0
  fi

  FAILED_CHECKS="$(echo "$CHECK_RUNS" | jq -r 'select(.status == "completed" and .conclusion != "success" and .conclusion != "skipped" and .conclusion != "neutral")')"

  if [ -n "$FAILED_CHECKS" ]; then
    write_ci_result false
    echo "Some CI checks failed:"
    echo "$FAILED_CHECKS" | jq -r '"\(.name): \(.conclusion)"'
    exit 0
  fi

  write_ci_result true
  echo "All CI checks passed"
  exit 0
done

write_ci_result false
echo "Timeout: CI did not complete within ${MAX_WAIT_TIME}s"
exit 0
