#!/usr/bin/env bash
# Verify that TAKT has usable Anthropic credentials before a long maintenance run.
#
# Resolution order matches script/run-takt-repo-maintenance.sh and the scheduled
# maintenance workflow: CLAUDE_CODE_OAUTH_TOKEN first, then the API key.
#
# The probe fails the step only on an unambiguous credential rejection
# (HTTP 401/403). Any other outcome (network failure, unexpected status) is
# reported as a warning so transient API issues never block maintenance.
set -euo pipefail

PROBE_URL="${ANTHROPIC_PROBE_URL:-https://api.anthropic.com/v1/models?limit=1}"
ANTHROPIC_VERSION="2023-06-01"
OAUTH_BETA="oauth-2025-04-20"

oauth_token="${CLAUDE_CODE_OAUTH_TOKEN:-}"
api_key="${TAKT_ANTHROPIC_API_KEY:-${ANTHROPIC_API_KEY:-}}"

emit_error() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::error title=TAKT authentication::$1"
  fi
  echo "error: $1" >&2
}

emit_warning() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::warning title=TAKT authentication::$1"
  fi
  echo "warning: $1" >&2
}

if [ -z "$oauth_token" ] && [ -z "$api_key" ]; then
  emit_error "CLAUDE_CODE_OAUTH_TOKEN, TAKT_ANTHROPIC_API_KEY, or ANTHROPIC_API_KEY is required for scheduled TAKT maintenance."
  exit 1
fi

if [ -n "$oauth_token" ]; then
  credential_name="CLAUDE_CODE_OAUTH_TOKEN"
  status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$PROBE_URL" \
    -H "authorization: Bearer $oauth_token" \
    -H "anthropic-beta: $OAUTH_BETA" \
    -H "anthropic-version: $ANTHROPIC_VERSION" || echo 000)"
else
  credential_name="TAKT_ANTHROPIC_API_KEY/ANTHROPIC_API_KEY"
  status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$PROBE_URL" \
    -H "x-api-key: $api_key" \
    -H "anthropic-version: $ANTHROPIC_VERSION" || echo 000)"
fi

case "$status" in
  2*)
    echo "ok: $credential_name accepted by the Anthropic API (HTTP $status)"
    ;;
  401 | 403)
    emit_error "$credential_name was rejected by the Anthropic API (HTTP $status). Rotate the secret in repository Actions secrets before re-running maintenance."
    exit 1
    ;;
  000)
    emit_warning "Could not reach $PROBE_URL to verify $credential_name. Continuing without verification."
    ;;
  *)
    emit_warning "Unexpected HTTP $status while verifying $credential_name. Continuing without verification."
    ;;
esac
