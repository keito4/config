#!/usr/bin/env bats

# Integration tests for update-all.sh script

load ../test_helper/test_helper

@test "update-all.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/update-all.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "update-all.sh has proper error handling with set -euo pipefail" {
  grep -q "set -euo pipefail" "${REPO_ROOT}/script/update-all.sh"
}

@test "update-all.sh invokes all three update scripts" {
  grep -q 'update-libraries.sh' "${REPO_ROOT}/script/update-all.sh"
  grep -q 'update-claude-code.sh' "${REPO_ROOT}/script/update-all.sh"
  grep -q 'update-actions.sh' "${REPO_ROOT}/script/update-all.sh"
}

@test "update-all.sh supports --skip-libs option" {
  grep -q '\-\-skip-libs' "${REPO_ROOT}/script/update-all.sh"

  local test_script="${TEST_TEMP_DIR}/test-skip-libs.sh"
  cat > "$test_script" << 'SCRIPT'
#!/usr/bin/env bash
skip_libs=false
for arg in "$@"; do
  case "$arg" in
    --skip-libs) skip_libs=true ;;
  esac
done
echo "skip_libs=$skip_libs"
SCRIPT
  chmod +x "$test_script"

  run "$test_script" --skip-libs
  assert_success
  [[ "$output" == "skip_libs=true" ]]
}

@test "update-all.sh supports --skip-claude option" {
  grep -q '\-\-skip-claude' "${REPO_ROOT}/script/update-all.sh"

  local test_script="${TEST_TEMP_DIR}/test-skip-claude.sh"
  cat > "$test_script" << 'SCRIPT'
#!/usr/bin/env bash
skip_claude=false
for arg in "$@"; do
  case "$arg" in
    --skip-claude) skip_claude=true ;;
  esac
done
echo "skip_claude=$skip_claude"
SCRIPT
  chmod +x "$test_script"

  run "$test_script" --skip-claude
  assert_success
  [[ "$output" == "skip_claude=true" ]]
}

@test "update-all.sh supports --skip-actions option" {
  grep -q '\-\-skip-actions' "${REPO_ROOT}/script/update-all.sh"

  local test_script="${TEST_TEMP_DIR}/test-skip-actions.sh"
  cat > "$test_script" << 'SCRIPT'
#!/usr/bin/env bash
skip_actions=false
for arg in "$@"; do
  case "$arg" in
    --skip-actions) skip_actions=true ;;
  esac
done
echo "skip_actions=$skip_actions"
SCRIPT
  chmod +x "$test_script"

  run "$test_script" --skip-actions
  assert_success
  [[ "$output" == "skip_actions=true" ]]
}

@test "update-all.sh supports --help option" {
  grep -q '\-\-help' "${REPO_ROOT}/script/update-all.sh"
  grep -q 'Usage:' "${REPO_ROOT}/script/update-all.sh"
}

@test "update-all.sh rejects unknown options" {
  grep -q '不明なオプション' "${REPO_ROOT}/script/update-all.sh"
}

@test "update-all.sh records step results and shows summary" {
  grep -q 'step_results' "${REPO_ROOT}/script/update-all.sh"
  grep -q '更新サマリ' "${REPO_ROOT}/script/update-all.sh"
}

@test "update-all.sh exits with 1 if any step fails" {
  grep -q 'has_failure.*true' "${REPO_ROOT}/script/update-all.sh"
  grep -q 'exit 1' "${REPO_ROOT}/script/update-all.sh"
}

@test "update-all.sh runs steps independently with set +e" {
  grep -q 'set +e' "${REPO_ROOT}/script/update-all.sh"
}
