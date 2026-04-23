#!/usr/bin/env bats
# Claude Code hooks integration tests
# Run Python-based hook tests as part of CI integration test suite

load ../test_helper/test_helper

@test "Python hook files are valid Python syntax" {
    hooks_dir="$REPO_ROOT/.claude/hooks"
    assert_directory_exists "$hooks_dir"

    for hook_file in "$hooks_dir"/*.py; do
        run python3 -m py_compile "$hook_file"
        assert_success
    done
}

@test "Python hook tests pass" {
    run python3 "$REPO_ROOT/test/python/test_hooks.py"
    assert_success
}
