#!/usr/bin/env bash

# Common test helper functions for integration tests

# Load bats support libraries if available
# shellcheck disable=SC1091
load_bats_support() {
  if [ -d "${BATS_TEST_DIRNAME}/../test_helper/bats-support" ]; then
    load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
  fi
}

# Setup function to run before each test
setup() {
  # Set up test environment
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/test-$$"
  mkdir -p "${TEST_TEMP_DIR}"
}

# Teardown function to run after each test
teardown() {
  # Clean up test environment
  if [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Helper function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Helper function to assert file exists
assert_file_exists() {
  local file="$1"
  [ -f "$file" ] || {
    echo "Expected file to exist: $file"
    return 1
  }
}

# Helper function to assert directory exists
assert_directory_exists() {
  local dir="$1"
  [ -d "$dir" ] || {
    echo "Expected directory to exist: $dir"
    return 1
  }
}
