#!/usr/bin/env bash
# Verify that a GitHub token can actually push to a repository, before a job
# spends time on work that ends in a failed push.
#
# The check this replaces only tested that the secret was non-empty. An expired
# CLAUDE_PAT passed it, so scheduled-maintenance ran for 45 minutes and then died
# at `git push` with `could not read Username` (keito4/config#1190), and
# sync-downstream failed inside actions/checkout with a bare `Bad credentials`
# (keito4/config#1188). Presence is not validity.
#
# Hard failures are the ones a person must fix: no token, a rejected token, a
# token that cannot reach the repository, a token without push, and a classic
# token missing `workflow` (needed because callers update .github/workflows/).
# Transient API trouble is only a warning, matching script/validate-takt-auth.sh
# — blaming the token for a GitHub outage sends people to fix the wrong thing,
# and a spurious failure issue every week is how real failures get ignored.
set -euo pipefail

API_URL="${GITHUB_TOKEN_API_URL:-https://api.github.com}"
TOKEN="${GITHUB_PR_TOKEN:-}"
REPO="${GITHUB_TOKEN_PROBE_REPO:-${GITHUB_REPOSITORY:-}}"
TOKEN_NAME="${GITHUB_PR_TOKEN_NAME:-CLAUDE_PR_GITHUB_TOKEN or CLAUDE_PAT}"

emit_error() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::error title=GitHub token::$1"
  fi
  echo "error: $1" >&2
}

emit_warning() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::warning title=GitHub token::$1"
  fi
  echo "warning: $1" >&2
}

if [ -z "$TOKEN" ]; then
  emit_error "$TOKEN_NAME is required because this workflow pushes branches and may update workflow files. Register one with: gh secret set CLAUDE_PR_GITHUB_TOKEN --repo ${REPO:-<owner/repo>}"
  exit 1
fi

if [ -z "$REPO" ]; then
  emit_error "GITHUB_TOKEN_PROBE_REPO (or GITHUB_REPOSITORY) must name the owner/repo to probe."
  exit 1
fi

work_dir="${RUNNER_TEMP:-$(mktemp -d)}"
body="${work_dir}/github-token-probe.json"
headers="${work_dir}/github-token-probe-headers.txt"

status="$(curl -sS --max-time 20 -o "$body" -D "$headers" -w '%{http_code}' \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "${API_URL}/repos/${REPO}" || echo 000)"

# GitHub also returns 403 for rate limiting, which is not a permission problem.
rate_limited() {
  grep -qi '^x-ratelimit-remaining:[[:space:]]*0' "$headers" 2>/dev/null
}

case "$status" in
  200) ;;
  401)
    emit_error "$TOKEN_NAME was rejected by the GitHub API (HTTP 401): the token is expired or revoked. Reissue it with the 'repo' and 'workflow' scopes and re-register it in repository Actions secrets."
    exit 1
    ;;
  403)
    if rate_limited; then
      emit_warning "GitHub API rate limit hit while verifying $TOKEN_NAME. Continuing without verification."
      exit 0
    fi
    emit_error "$TOKEN_NAME is live but cannot see ${REPO} (HTTP 403). Grant the token access to this repository."
    exit 1
    ;;
  404)
    emit_error "$TOKEN_NAME is live but cannot see ${REPO} (HTTP 404). Grant the token access to this repository."
    exit 1
    ;;
  000)
    emit_warning "Could not reach ${API_URL} to verify $TOKEN_NAME. Continuing without verification."
    exit 0
    ;;
  429 | 5??)
    emit_warning "GitHub API returned HTTP $status while verifying $TOKEN_NAME (rate limiting or an outage). Continuing without verification."
    exit 0
    ;;
  *)
    emit_warning "Unexpected HTTP $status while verifying $TOKEN_NAME. Continuing without verification."
    exit 0
    ;;
esac

if [ "$(jq -r '.permissions.push // false' "$body")" != "true" ]; then
  emit_error "$TOKEN_NAME can read ${REPO} but cannot push to it. This workflow opens pull requests, so it needs write access."
  exit 1
fi

# Only classic tokens report scopes. A fine-grained token returns no header, and
# an absent header must not be read as an absent scope.
scopes="$(grep -i '^x-oauth-scopes:' "$headers" | cut -d: -f2- | tr -d ' \r' || true)"
if [ -n "$scopes" ] && ! printf '%s' ",${scopes}," | grep -q ',workflow,'; then
  emit_error "$TOKEN_NAME is missing the 'workflow' scope (has: ${scopes}). Pushes that touch .github/workflows/ will be rejected. Reissue the token with both 'repo' and 'workflow'."
  exit 1
fi

echo "ok: $TOKEN_NAME can push to ${REPO}"
