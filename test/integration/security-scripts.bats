#!/usr/bin/env bats
# Security scripts integration tests

load ../test_helper/test_helper

# ==================== Script Existence Tests ====================

@test "security-credential-scan.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/security-credential-scan.sh"
    [ -x "$REPO_ROOT/script/security-credential-scan.sh" ]
}

@test "code-complexity-check.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/code-complexity-check.sh"
    [ -x "$REPO_ROOT/script/code-complexity-check.sh" ]
}

# ==================== Help Command Tests ====================

@test "security-credential-scan.sh --help shows usage" {
    run "$REPO_ROOT/script/security-credential-scan.sh" --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "--strict"
    assert_output --partial "--json"
}

@test "code-complexity-check.sh --help shows usage" {
    run "$REPO_ROOT/script/code-complexity-check.sh" --help
    assert_success
    assert_output --partial "Usage:"
}

# ==================== Functional Tests ====================

@test "security-credential-scan.sh can scan a directory" {
    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$REPO_ROOT/test"
    assert_success
}

@test "security-credential-scan.sh supports JSON output" {
    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$REPO_ROOT/test" --json
    assert_success
    # Should output valid JSON
    assert_output --partial '"critical_count"'
    assert_output --partial '"findings"'
}

@test "security-credential-scan.sh detects no secrets in clean test directory" {
    # Create a clean temp directory
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    echo "const x = 1;" > "$temp_dir/clean.js"

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$temp_dir"
    assert_success
    assert_output --partial "No credentials found"
}

@test "security-credential-scan.sh detects AWS keys in test file" {
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Create file with fake AWS key pattern
    echo 'const key = "AKIAIOSFODNN7EXAMPLE";' > "$temp_dir/test.js"

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$temp_dir"
    assert_success
    assert_output --partial "AWS Access Key"
}

@test "security-credential-scan.sh strict mode fails on critical findings" {
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Create file with fake AWS key pattern
    echo 'const key = "AKIAIOSFODNN7EXAMPLE";' > "$temp_dir/test.js"

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$temp_dir" --strict
    assert_failure
}
