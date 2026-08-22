#!/usr/bin/env bats
# Behavioral tests for script/version.sh (semantic version tag bumping)
#
# All bump/dry-run scenarios operate on a scratch repo, and --dry-run is
# always used so no real tags are ever created.

load ../test_helper/test_helper

SCRIPT_UNDER_TEST=""

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/test-$$"
  mkdir -p "${TEST_TEMP_DIR}"
  SCRIPT_UNDER_TEST="${REPO_ROOT}/script/version.sh"

  WORK_REPO="${TEST_TEMP_DIR}/work"
  mkdir -p "$WORK_REPO"
  git -C "$WORK_REPO" init -q
  git -C "$WORK_REPO" config user.email "test@example.com"
  git -C "$WORK_REPO" config user.name "Test User"
  echo init > "$WORK_REPO/file.txt"
  git -C "$WORK_REPO" add file.txt
  git -C "$WORK_REPO" commit -q -m init
}

teardown() {
  if [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

@test "--help shows usage and exits 0" {
  cd "$WORK_REPO"
  run bash "$SCRIPT_UNDER_TEST" --help
  assert_success
  [[ "$output" == *"Usage:"* ]]
}

@test "starts at v1.0.0 when no tags exist (dry run)" {
  cd "$WORK_REPO"
  run bash "$SCRIPT_UNDER_TEST" --dry-run
  assert_success
  [[ "$output" == *"v1.0.0"* ]]
  [ "$(git tag -l 'v*' | wc -l | tr -d ' ')" -eq 0 ]
}

@test "bumps patch version from the latest tag (dry run)" {
  cd "$WORK_REPO"
  git tag v1.2.3
  run bash "$SCRIPT_UNDER_TEST" --type patch --dry-run
  assert_success
  [[ "$output" == *"v1.2.4"* ]]
}

@test "bumps minor version and resets patch (dry run)" {
  cd "$WORK_REPO"
  git tag v1.2.3
  run bash "$SCRIPT_UNDER_TEST" --type minor --dry-run
  assert_success
  [[ "$output" == *"v1.3.0"* ]]
}

@test "bumps major version and resets minor/patch (dry run)" {
  cd "$WORK_REPO"
  git tag v1.2.3
  run bash "$SCRIPT_UNDER_TEST" --type major --dry-run
  assert_success
  [[ "$output" == *"v2.0.0"* ]]
}

@test "rejects an invalid bump type" {
  cd "$WORK_REPO"
  run bash "$SCRIPT_UNDER_TEST" --type bogus --dry-run
  assert_failure
  [[ "$output" == *"Invalid bump type"* ]]
}

@test "dry run never creates a tag" {
  cd "$WORK_REPO"
  git tag v1.0.0
  run bash "$SCRIPT_UNDER_TEST" --dry-run
  assert_success
  [ "$(git tag -l 'v1.0.1')" = "" ]
}
