#!/usr/bin/env bats
# Behavioral tests for .gitignore
#
# git treats a trailing slash as "directories only". A symlink is not a
# directory to git, so `node_modules/` silently fails to ignore a symlink
# named node_modules — and `git add -A` picks it up. That is not theoretical:
# on 2026-09-05 a worktree's node_modules symlink was committed this way.
# These tests exercise the real matcher instead of grepping the file.

load ../test_helper/test_helper

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/test-$$"
  mkdir -p "${TEST_TEMP_DIR}"

  # 実物の .gitignore を使い捨てリポジトリへ写して、git 本体に判定させる
  WORK_REPO="${TEST_TEMP_DIR}/work"
  mkdir -p "$WORK_REPO"
  git -C "$WORK_REPO" init -q
  cp "${REPO_ROOT}/.gitignore" "$WORK_REPO/.gitignore"
}

teardown() {
  if [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

@test "a node_modules symlink is ignored" {
  mkdir -p "${TEST_TEMP_DIR}/real-node-modules"
  ln -s "${TEST_TEMP_DIR}/real-node-modules" "$WORK_REPO/node_modules"

  run git -C "$WORK_REPO" check-ignore -q node_modules
  assert_success
}

@test "a node_modules symlink does not show up as an untracked change" {
  mkdir -p "${TEST_TEMP_DIR}/real-node-modules"
  ln -s "${TEST_TEMP_DIR}/real-node-modules" "$WORK_REPO/node_modules"

  run git -C "$WORK_REPO" status --porcelain
  assert_success
  ! printf '%s\n' "$output" | grep -q 'node_modules'
}

@test "a node_modules directory is still ignored" {
  mkdir -p "$WORK_REPO/node_modules/some-package"
  touch "$WORK_REPO/node_modules/some-package/index.js"

  run git -C "$WORK_REPO" check-ignore -q node_modules/some-package/index.js
  assert_success
}

# result は Nix のビルド出力 symlink。末尾スラッシュなしで書かれており、
# node_modules もこれに揃える。
@test "the Nix result symlink stays ignored" {
  mkdir -p "${TEST_TEMP_DIR}/nix-out"
  ln -s "${TEST_TEMP_DIR}/nix-out" "$WORK_REPO/result"

  run git -C "$WORK_REPO" check-ignore -q result
  assert_success
}
