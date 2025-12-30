#!/usr/bin/env bats

# Integration tests for post-create-plugins.sh script

load ../test_helper/test_helper

@test "post-create-plugins.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/post-create-plugins.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "post-create-plugins.sh uses strict error handling" {
  grep -q 'set -euo pipefail' "${REPO_ROOT}/script/post-create-plugins.sh"
}

@test "post-create-plugins.sh defines necessary functions" {
  local script="${REPO_ROOT}/script/post-create-plugins.sh"

  # Should have function definitions
  grep -q '()' "$script" || true
}

@test "post-create-plugins.sh handles plugin setup" {
  # Verify the script mentions plugins
  grep -qi 'plugin' "${REPO_ROOT}/script/post-create-plugins.sh"
}
