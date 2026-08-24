#!/usr/bin/env bats
# Behavioral tests for script/check-file-length.sh
#
# The script gates every git commit via husky, so its warn/hard line-count
# thresholds and .filelengthignore handling are important to verify.

load ../test_helper/test_helper

SCRIPT_UNDER_TEST=""

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/test-$$"
  mkdir -p "${TEST_TEMP_DIR}"
  SCRIPT_UNDER_TEST="${REPO_ROOT}/script/check-file-length.sh"

  WORK_REPO="${TEST_TEMP_DIR}/work"
  mkdir -p "$WORK_REPO"
  git -C "$WORK_REPO" init -q
  git -C "$WORK_REPO" config user.email "test@example.com"
  git -C "$WORK_REPO" config user.name "Test User"
}

teardown() {
  if [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Stage a JS file with the given number of lines.
stage_file_with_lines() {
  local name="$1"
  local lines="$2"
  local i
  : > "$WORK_REPO/$name"
  for ((i = 1; i <= lines; i++)); do
    echo "line $i" >> "$WORK_REPO/$name"
  done
  git -C "$WORK_REPO" add "$name"
}

@test "does not warn or error for a file under the warn limit" {
  cd "$WORK_REPO"
  stage_file_with_lines "small.js" 2

  run env FILE_LENGTH_HARD_LIMIT=5 FILE_LENGTH_WARN_LIMIT=3 bash "$SCRIPT_UNDER_TEST"
  assert_success
  [ -z "$output" ]
}

@test "warns but does not block for a file at/above the warn limit" {
  cd "$WORK_REPO"
  stage_file_with_lines "medium.js" 4

  run env FILE_LENGTH_HARD_LIMIT=5 FILE_LENGTH_WARN_LIMIT=3 bash "$SCRIPT_UNDER_TEST"
  assert_success
  [[ "$output" == *"⚠️"* ]]
  [[ "$output" == *"medium.js"* ]]
}

@test "errors and blocks for a file at/above the hard limit" {
  cd "$WORK_REPO"
  stage_file_with_lines "big.js" 6

  run env FILE_LENGTH_HARD_LIMIT=5 FILE_LENGTH_WARN_LIMIT=3 bash "$SCRIPT_UNDER_TEST"
  assert_failure
  [[ "$output" == *"❌"* ]]
  [[ "$output" == *"big.js"* ]]
}

@test "skips files matched by .filelengthignore even when they exceed the hard limit" {
  cd "$WORK_REPO"
  echo "ignored.js" > "$WORK_REPO/.filelengthignore"
  git -C "$WORK_REPO" add .filelengthignore
  stage_file_with_lines "ignored.js" 10

  run env FILE_LENGTH_HARD_LIMIT=5 FILE_LENGTH_WARN_LIMIT=3 bash "$SCRIPT_UNDER_TEST"
  assert_success
  [[ "$output" != *"ignored.js"* ]]
}

@test "produces no output when no JS/TS files are staged" {
  cd "$WORK_REPO"
  echo "# docs" > "$WORK_REPO/README.md"
  git -C "$WORK_REPO" add README.md

  run env FILE_LENGTH_HARD_LIMIT=5 FILE_LENGTH_WARN_LIMIT=3 bash "$SCRIPT_UNDER_TEST"
  assert_success
  [ -z "$output" ]
}
