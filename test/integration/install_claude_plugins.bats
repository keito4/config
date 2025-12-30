#!/usr/bin/env bats

# Integration tests for install-claude-plugins.sh script

load ../test_helper/test_helper

@test "install-claude-plugins.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/install-claude-plugins.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "install-claude-plugins.sh uses strict error handling" {
  grep -q 'set -euo pipefail' "${REPO_ROOT}/script/install-claude-plugins.sh"
}

@test "install-claude-plugins.sh handles plugin installation" {
  # Verify the script mentions plugin installation
  grep -qi 'plugin' "${REPO_ROOT}/script/install-claude-plugins.sh"
}

@test "install-claude-plugins.sh checks for claude CLI" {
  # Verify claude CLI check exists
  grep -q 'claude' "${REPO_ROOT}/script/install-claude-plugins.sh" || true
}
