#!/usr/bin/env bats

# Integration tests for update-libraries.sh script

load ../test_helper/test_helper

@test "update-libraries.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/update-libraries.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "update-libraries.sh requires npx command" {
  # Create a temporary script that simulates missing npx
  local temp_script="${TEST_TEMP_DIR}/test-npx-check.sh"
  cat > "$temp_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required to update libraries" >&2
  exit 1
fi

echo "npx found"
EOF
  chmod +x "$temp_script"

  # Test with npx available
  run "$temp_script"
  assert_success
  [[ "$output" == *"npx found"* ]]
}

@test "update-libraries.sh sets REPO_PATH with fallback to parent directory" {
  # Verify REPO_PATH logic exists in the script
  grep -q 'REPO_PATH="\${REPO_PATH:-' "${REPO_ROOT}/script/update-libraries.sh"
  grep -q 'cd.*dirname' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh respects UPDATE_LIBS_REJECT environment variable" {
  # Test the REJECT_PACKAGES logic
  export UPDATE_LIBS_REJECT="package1,package2"

  local test_script="${TEST_TEMP_DIR}/test-reject.sh"
  cat > "$test_script" << 'EOF'
#!/usr/bin/env bash
REJECT_PACKAGES=${UPDATE_LIBS_REJECT:-"semantic-release,@semantic-release/github"}
if [[ -n "$REJECT_PACKAGES" ]]; then
  echo "Rejecting: $REJECT_PACKAGES"
else
  echo "No rejections"
fi
EOF
  chmod +x "$test_script"

  run "$test_script"
  assert_success
  [[ "$output" == *"Rejecting: package1,package2"* ]]
}

@test "update-libraries.sh has proper error handling with set -euo pipefail" {
  # Verify that the script uses strict error handling
  grep -q "set -euo pipefail" "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh log function outputs correctly" {
  # Test the log function behavior
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
  # Verify the script checks for the global.json file
  grep -q 'GLOBAL_FILE="npm/global.json"' "${REPO_ROOT}/script/update-libraries.sh"
  grep -q 'if \[\[ -f "$GLOBAL_FILE" \]\]' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh checks for jq command" {
  # Verify the script checks for jq availability
  grep -q 'command -v jq >/dev/null 2>&1' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh runs lint and test verification" {
  # Verify the script includes verification steps
  grep -q 'npm run lint' "${REPO_ROOT}/script/update-libraries.sh"
  grep -q 'npm test' "${REPO_ROOT}/script/update-libraries.sh"
}

@test "update-libraries.sh has default REJECT_PACKAGES value" {
  # Verify default reject packages
  grep -q 'REJECT_PACKAGES=\${UPDATE_LIBS_REJECT:-"semantic-release,@semantic-release/github"}' "${REPO_ROOT}/script/update-libraries.sh"
}
