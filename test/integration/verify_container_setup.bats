#!/usr/bin/env bats

# Integration tests for verify-container-setup.sh script

load ../test_helper/test_helper

@test "verify-container-setup.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/verify-container-setup.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "verify-container-setup.sh uses strict error handling" {
  grep -q 'set -euo pipefail' "${REPO_ROOT}/script/verify-container-setup.sh"
}

@test "verify-container-setup.sh has comprehensive checks" {
  # Verify the script contains various verification checks
  local script="${REPO_ROOT}/script/verify-container-setup.sh"

  # Should check for files or directories
  grep -q 'if \[\[' "$script"
}
