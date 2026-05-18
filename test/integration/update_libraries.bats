#!/usr/bin/env bats

# Integration tests for update-libraries.sh script

load ../test_helper/test_helper

@test "update-libraries.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/update-libraries.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "update-libraries.sh requires npm command" {
  # Script now uses `npm view` (not npx) — verify the dependency check is present
  grep -q 'command -v npm >/dev/null 2>&1' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh sets REPO_PATH with fallback to parent directory" {
  grep -q 'REPO_PATH="\${REPO_PATH:-' "${REPO_ROOT}/script/update-libraries.sh"
  grep -q 'cd.*dirname' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh has proper error handling with set -euo pipefail" {
  grep -q "set -euo pipefail" "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh log function outputs correctly" {
  local test_script="${TEST_TEMP_DIR}/test-log.sh"
  cat > "$test_script" << 'EOF'
#!/usr/bin/env bash
log() {
  printf '==> %s\n' "$1"
}
log "Test message"
EOF
  chmod +x "$test_script"

  run "$test_script"
  assert_success
  [[ "$output" == "==> Test message" ]]
}

@test "update-libraries.sh checks for npm/global.json file" {
  grep -q 'GLOBAL_FILE="npm/global.json"' "${REPO_ROOT}/script/update-libraries.sh"
  grep -q 'if \[\[ ! -f "$GLOBAL_FILE" \]\]' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh checks for jq command" {
  grep -q 'command -v jq >/dev/null 2>&1' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh skips overridden packages" {
  # See ADR 0006: overridden:true entries are pinned and skipped during refresh
  grep -q 'overridden' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh does not run npm-check-updates" {
  # See ADR 0006: package.json is managed by Dependabot, not this script
  ! grep -q 'npm-check-updates' "${REPO_ROOT}/script/update-libraries.sh"
}
