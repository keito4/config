#!/usr/bin/env bats

# Integration tests for script/validate-github-token.sh.
#
# keito4/config#1190 の再発防止。従来の検査は `-z` しか見ておらず、失効した
# CLAUDE_PAT でも通過していた。scheduled-maintenance は 45 分走り切ってから
# push で `could not read Username` (exit 128) になり、4 週連続で落ちていた。

load ../test_helper/test_helper

# curl のスタブ。ヘッダファイル(-D)とボディ(-o)を書き、HTTP コードを stdout に出す。
setup_curl_stub() {
  export STUB_DIR="${TEST_TEMP_DIR}/stub"
  export CURL_ARGS_FILE="${TEST_TEMP_DIR}/curl-args"
  mkdir -p "$STUB_DIR"

  cat > "${STUB_DIR}/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CURL_ARGS_FILE"
if [ -n "${STUB_CURL_FAIL:-}" ]; then
  exit 1
fi
body=""; headers=""
prev=""
for arg in "$@"; do
  case "$prev" in
    -o) body="$arg" ;;
    -D) headers="$arg" ;;
  esac
  prev="$arg"
done
[ -n "$body" ] && printf '%s' "${STUB_BODY:-{\"permissions\":{\"push\":true}}}" > "$body"
[ -n "$headers" ] && printf 'HTTP/2 %s\r\n%s\r\n' "${STUB_HTTP_CODE:-200}" "${STUB_SCOPES_HEADER:-}" > "$headers"
printf '%s' "${STUB_HTTP_CODE:-200}"
STUB
  chmod +x "${STUB_DIR}/curl"
  export PATH="${STUB_DIR}:${PATH}"
}

run_validate() {
  env -u GITHUB_ACTIONS \
    PATH="$PATH" \
    CURL_ARGS_FILE="$CURL_ARGS_FILE" \
    RUNNER_TEMP="${TEST_TEMP_DIR}" \
    STUB_HTTP_CODE="${STUB_HTTP_CODE:-200}" \
    STUB_BODY="${STUB_BODY:-}" \
    STUB_SCOPES_HEADER="${STUB_SCOPES_HEADER:-}" \
    STUB_CURL_FAIL="${STUB_CURL_FAIL:-}" \
    GITHUB_PR_TOKEN="${GITHUB_PR_TOKEN:-}" \
    GITHUB_TOKEN_PROBE_REPO="${GITHUB_TOKEN_PROBE_REPO:-keito4/config}" \
    "${REPO_ROOT}/script/validate-github-token.sh"
}

@test "validate-github-token fails when no token is configured" {
  setup_curl_stub

  run run_validate

  [ "$status" -eq 1 ]
  [[ "$output" == *"is required"* ]]
}

@test "validate-github-token accepts a token that can push and probes the repository" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_valid"

  run run_validate

  [ "$status" -eq 0 ]
  grep -Fq "https://api.github.com/repos/keito4/config" "$CURL_ARGS_FILE"
  grep -Fq "Authorization: Bearer ghp_valid" "$CURL_ARGS_FILE"
}

# 本命の回帰。空でないだけの失効トークンを通すと、45 分走ってから push で落ちる。
@test "validate-github-token rejects an expired token instead of passing it through" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_expired"
  export STUB_HTTP_CODE="401"

  run run_validate

  [ "$status" -eq 1 ]
  [[ "$output" == *"expired or revoked"* ]]
}

@test "validate-github-token rejects a token that cannot see the repository" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_scoped_elsewhere"
  export STUB_HTTP_CODE="404"

  run run_validate

  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot see"* ]]
}

@test "validate-github-token rejects a read-only token" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_readonly"
  export STUB_BODY='{"permissions":{"push":false}}'

  run run_validate

  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot push"* ]]
}

# このワークフローは .github/workflows/ を更新しうるので workflow スコープは必須。
@test "validate-github-token rejects a classic token without the workflow scope" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_no_workflow"
  export STUB_SCOPES_HEADER="x-oauth-scopes: repo, gist"

  run run_validate

  [ "$status" -eq 1 ]
  [[ "$output" == *"workflow"* ]]
}

@test "validate-github-token accepts a classic token that has the workflow scope" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_full"
  export STUB_SCOPES_HEADER="x-oauth-scopes: repo, workflow"

  run run_validate

  [ "$status" -eq 0 ]
}

# fine-grained PAT は x-oauth-scopes を返さない。無いことを欠落と誤認しない。
@test "validate-github-token accepts a fine-grained token that returns no scope header" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="github_pat_finegrained"
  export STUB_SCOPES_HEADER="content-type: application/json"

  run run_validate

  [ "$status" -eq 0 ]
}

# 一時障害でトークンを疑わせない。validate-takt-auth.sh と同じ判断。
@test "validate-github-token warns but continues when the API is unreachable" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_valid"
  export STUB_CURL_FAIL="1"

  run run_validate

  [ "$status" -eq 0 ]
  [[ "$output" == *"warning"* ]]
}

@test "validate-github-token warns but continues on rate limiting" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_valid"
  export STUB_HTTP_CODE="429"

  run run_validate

  [ "$status" -eq 0 ]
  [[ "$output" == *"warning"* ]]
}

@test "validate-github-token warns but continues on a GitHub outage" {
  setup_curl_stub
  export GITHUB_PR_TOKEN="ghp_valid"
  export STUB_HTTP_CODE="503"

  run run_validate

  [ "$status" -eq 0 ]
  [[ "$output" == *"warning"* ]]
}
