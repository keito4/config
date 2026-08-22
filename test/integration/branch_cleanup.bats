#!/usr/bin/env bats
# Behavioral tests for script/branch-cleanup.sh
#
# Every scenario runs with --dry-run so no branch is ever actually deleted.
# A local bare repo is wired up as "origin" so `git fetch --prune` and the
# main-branch detection succeed without any network access.

load ../test_helper/test_helper

SCRIPT_UNDER_TEST=""

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/test-$$"
  mkdir -p "${TEST_TEMP_DIR}"
  SCRIPT_UNDER_TEST="${REPO_ROOT}/script/branch-cleanup.sh"

  ORIGIN_REPO="${TEST_TEMP_DIR}/origin.git"
  WORK_REPO="${TEST_TEMP_DIR}/work"
  git init -q --bare -b main "$ORIGIN_REPO"

  mkdir -p "$WORK_REPO"
  git -C "$WORK_REPO" init -q -b main
  git -C "$WORK_REPO" config user.email "test@example.com"
  git -C "$WORK_REPO" config user.name "Test User"
  echo init > "$WORK_REPO/file.txt"
  git -C "$WORK_REPO" add file.txt
  git -C "$WORK_REPO" commit -q -m init
  git -C "$WORK_REPO" remote add origin "$ORIGIN_REPO"
  git -C "$WORK_REPO" push -q origin main
}

teardown() {
  if [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Commit on the currently checked out branch with a specific commit date.
commit_with_date() {
  local date="$1"
  shift
  echo "$*" >> "$WORK_REPO/file.txt"
  git -C "$WORK_REPO" add file.txt
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" git -C "$WORK_REPO" commit -q -m "$*"
}

@test "--help shows usage and exits 0" {
  cd "$WORK_REPO"
  run bash "$SCRIPT_UNDER_TEST" --help
  assert_success
  [[ "$output" == *"Usage:"* ]]
}

@test "an unknown option exits with an error" {
  cd "$WORK_REPO"
  run bash "$SCRIPT_UNDER_TEST" --bogus-option
  assert_failure
}

@test "reports nothing to clean up when only the current branch exists" {
  cd "$WORK_REPO"
  run bash "$SCRIPT_UNDER_TEST" --dry-run
  assert_success
  [[ "$output" == *"No branches to clean up!"* ]]
}

@test "lists a merged branch as cleanable in dry-run without deleting it" {
  cd "$WORK_REPO"
  git -C "$WORK_REPO" branch feature-merged
  run bash "$SCRIPT_UNDER_TEST" --dry-run --merged-only
  assert_success
  [[ "$output" == *"Merged (1)"* ]]
  [[ "$output" == *"feature-merged"* ]]
  [[ "$output" == *"Dry run mode"* ]]
  # branch must still exist after --dry-run
  git -C "$WORK_REPO" rev-parse --verify feature-merged
}

@test "excludes protected branch names even when merged" {
  cd "$WORK_REPO"
  git -C "$WORK_REPO" branch develop
  run bash "$SCRIPT_UNDER_TEST" --dry-run --merged-only
  assert_success
  [[ "$output" == *"No branches to clean up!"* ]]
}

@test "detects a stale unmerged branch based on --stale-days" {
  cd "$WORK_REPO"
  git -C "$WORK_REPO" checkout -q -b feature-stale
  commit_with_date "2000-01-01T00:00:00" "old commit on feature-stale"
  git -C "$WORK_REPO" checkout -q main

  run bash "$SCRIPT_UNDER_TEST" --dry-run --stale-days 1
  assert_success
  [[ "$output" == *"Stale (1)"* ]]
  [[ "$output" == *"feature-stale"* ]]
}

@test "--merged-only suppresses stale branch reporting" {
  cd "$WORK_REPO"
  git -C "$WORK_REPO" checkout -q -b feature-stale
  commit_with_date "2000-01-01T00:00:00" "old commit on feature-stale"
  git -C "$WORK_REPO" checkout -q main

  run bash "$SCRIPT_UNDER_TEST" --dry-run --merged-only --stale-days 1
  assert_success
  [[ "$output" != *"Stale"* ]]
  [[ "$output" == *"No branches to clean up!"* ]]
}
