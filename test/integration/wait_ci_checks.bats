#!/usr/bin/env bats
# wait-ci-checks integration tests

load ../test_helper/test_helper

@test "wait-ci-checks.sh accepts duplicate successful Quality Gate runs" {
    CHECK_RUNS_JSON='[
      {"name":"Quality Gate","status":"completed","conclusion":"success"},
      {"name":"Quality Gate","status":"completed","conclusion":"success"},
      {"name":"Workflow Lint","status":"completed","conclusion":"success"}
    ]'

    run env CHECK_RUNS_JSON="$CHECK_RUNS_JSON" "$REPO_ROOT/script/wait-ci-checks.sh" keito4/config deadbeef
    assert_success
    assert_output --partial "All CI checks passed"
}

@test "wait-ci-checks.sh reports failed duplicate Quality Gate runs" {
    CHECK_RUNS_JSON='[
      {"name":"Quality Gate","status":"completed","conclusion":"success"},
      {"name":"Quality Gate","status":"completed","conclusion":"failure"}
    ]'

    output_file="$TEST_TEMP_DIR/github-output"
    run env CHECK_RUNS_JSON="$CHECK_RUNS_JSON" GITHUB_OUTPUT="$output_file" "$REPO_ROOT/script/wait-ci-checks.sh" keito4/config deadbeef
    assert_success
    assert_output --partial "Quality Gate failed"
    grep -q "ci_passed=false" "$output_file"
}

@test "wait-ci-checks.sh proceeds when path-filtered CI has no Detect Changes check" {
    CHECK_RUNS_JSON='[
      {"name":"GitGuardian Security Checks","status":"completed","conclusion":"success"}
    ]'

    run env CHECK_RUNS_JSON="$CHECK_RUNS_JSON" QUALITY_GATE_MISSING_GRACE=0 "$REPO_ROOT/script/wait-ci-checks.sh" keito4/config deadbeef
    assert_success
    assert_output --partial "CI workflow skipped by path filters"
}
