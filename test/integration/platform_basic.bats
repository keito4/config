#!/usr/bin/env bats

# Basic integration tests for shell scripts
# This is a sample test to verify the bats framework is working correctly

load ../test_helper/test_helper

@test "setup-claude.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/setup-claude.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "script directory contains expected files" {
  local script_dir="${REPO_ROOT}/script"
  assert_directory_exists "$script_dir"

  # Verify key scripts exist
  assert_file_exists "${script_dir}/setup-claude.sh"
  assert_file_exists "${script_dir}/update-libraries.sh"
}

@test "required commands are available" {
  # Verify essential commands exist
  command_exists "bash"
  command_exists "git"
}

@test "test helper functions work correctly" {
  # Test assert_file_exists helper
  local temp_file="${TEST_TEMP_DIR}/test_file"
  touch "$temp_file"
  assert_file_exists "$temp_file"

  # Test assert_directory_exists helper
  local temp_dir="${TEST_TEMP_DIR}/test_dir"
  mkdir -p "$temp_dir"
  assert_directory_exists "$temp_dir"
}
