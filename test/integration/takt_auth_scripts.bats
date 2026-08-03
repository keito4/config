#!/usr/bin/env bats

# Integration tests for the scheduled-maintenance TAKT credential scripts.

load ../test_helper/test_helper

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
printf '%s' "${STUB_HTTP_CODE:-200}"
STUB
  chmod +x "${STUB_DIR}/curl"
  export PATH="${STUB_DIR}:${PATH}"
}

run_validate() {
  env -u GITHUB_ACTIONS \
    PATH="$PATH" \
    CURL_ARGS_FILE="$CURL_ARGS_FILE" \
    STUB_HTTP_CODE="${STUB_HTTP_CODE:-200}" \
    STUB_CURL_FAIL="${STUB_CURL_FAIL:-}" \
    CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN:-}" \
    TAKT_ANTHROPIC_API_KEY="${TAKT_ANTHROPIC_API_KEY:-}" \
    ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
    "${REPO_ROOT}/script/validate-takt-auth.sh"
}

@test "validate-takt-auth fails when no credential is configured" {
  setup_curl_stub

  run run_validate

  [ "$status" -eq 1 ]
  [[ "$output" == *"CLAUDE_CODE_OAUTH_TOKEN, TAKT_ANTHROPIC_API_KEY, or ANTHROPIC_API_KEY is required"* ]]
}

@test "validate-takt-auth accepts a working OAuth token and probes with a bearer header" {
  setup_curl_stub
  export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat-test"
  export STUB_HTTP_CODE="200"

  run run_validate

  [ "$status" -eq 0 ]
  [[ "$output" == *"CLAUDE_CODE_OAUTH_TOKEN accepted"* ]]
  grep -Fq "authorization: Bearer sk-ant-oat-test" "$CURL_ARGS_FILE"
}

@test "validate-takt-auth probes with x-api-key when only an API key is configured" {
  setup_curl_stub
  export TAKT_ANTHROPIC_API_KEY="sk-ant-api-test"
  export STUB_HTTP_CODE="200"

  run run_validate

  [ "$status" -eq 0 ]
  grep -Fq "x-api-key: sk-ant-api-test" "$CURL_ARGS_FILE"
}

@test "validate-takt-auth falls back to ANTHROPIC_API_KEY" {
  setup_curl_stub
  export ANTHROPIC_API_KEY="sk-ant-fallback"
  export STUB_HTTP_CODE="200"

  run run_validate

  [ "$status" -eq 0 ]
  grep -Fq "x-api-key: sk-ant-fallback" "$CURL_ARGS_FILE"
}

@test "validate-takt-auth fails fast on a rejected credential" {
  setup_curl_stub
  export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat-expired"
  export STUB_HTTP_CODE="401"

  run run_validate

  [ "$status" -eq 1 ]
  [[ "$output" == *"CLAUDE_CODE_OAUTH_TOKEN was rejected"* ]]
  [[ "$output" == *"HTTP 401"* ]]
}

@test "validate-takt-auth does not block on an unreachable API" {
  setup_curl_stub
  export TAKT_ANTHROPIC_API_KEY="sk-ant-api-test"
  export STUB_CURL_FAIL="1"

  run run_validate

  [ "$status" -eq 0 ]
  [[ "$output" == *"Could not reach"* ]]
}

@test "validate-takt-auth does not block on an unexpected status" {
  setup_curl_stub
  export TAKT_ANTHROPIC_API_KEY="sk-ant-api-test"
  export STUB_HTTP_CODE="500"

  run run_validate

  [ "$status" -eq 0 ]
  [[ "$output" == *"Unexpected HTTP 500"* ]]
}

@test "trust-claude-workspace marks the workspace as trusted" {
  local fake_home="${TEST_TEMP_DIR}/home"
  local workspace="${TEST_TEMP_DIR}/workspace"
  mkdir -p "$fake_home" "$workspace"

  run env HOME="$fake_home" "${REPO_ROOT}/script/trust-claude-workspace.sh" "$workspace"

  [ "$status" -eq 0 ]
  assert_file_exists "${fake_home}/.claude.json"
  node -e '
    const fs = require("node:fs");
    const config = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (config.projects[process.argv[2]].hasTrustDialogAccepted !== true) {
      throw new Error("workspace was not trusted");
    }
  ' "${fake_home}/.claude.json" "$workspace"
}

@test "trust-claude-workspace preserves unrelated ~/.claude.json content" {
  local fake_home="${TEST_TEMP_DIR}/home-existing"
  local workspace="${TEST_TEMP_DIR}/workspace-existing"
  mkdir -p "$fake_home" "$workspace"
  printf '%s\n' '{"numStartups":7,"projects":{"/other":{"allowedTools":["Bash"]}}}' > "${fake_home}/.claude.json"

  run env HOME="$fake_home" "${REPO_ROOT}/script/trust-claude-workspace.sh" "$workspace"

  [ "$status" -eq 0 ]
  node -e '
    const fs = require("node:fs");
    const config = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (config.numStartups !== 7) throw new Error("unrelated key lost");
    if (config.projects["/other"].allowedTools[0] !== "Bash") throw new Error("other project lost");
    if (config.projects[process.argv[2]].hasTrustDialogAccepted !== true) {
      throw new Error("workspace was not trusted");
    }
  ' "${fake_home}/.claude.json" "$workspace"
}
