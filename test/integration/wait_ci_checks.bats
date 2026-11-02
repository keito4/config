#!/usr/bin/env bats
# Actual shell regressions include duplicate/stale gates and missing CI.
load ../test_helper/test_helper

@test "wait-ci-checks.sh verifies workflow identity and fails closed" {
    cd "$REPO_ROOT"
    run node --test tests/workflows/ci-waiter.test.mjs
    assert_success
}
