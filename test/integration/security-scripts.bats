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

@test "security-credential-scan.sh detects AWS temporary (ASIA) keys" {
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # STS temporary credentials use the ASIA prefix
    echo 'const key = "ASIAIOSFODNN7EXAMPLE";' > "$temp_dir/test.js"

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$temp_dir"
    assert_success
    assert_output --partial "AWS Access Key"
}

@test "security-credential-scan.sh scans .claude/settings.local.json for inline secrets" {
    mkdir -p "$TEST_TEMP_DIR/.claude"
    cat > "$TEST_TEMP_DIR/.claude/settings.local.json" <<'JSON'
{
  "permissions": {
    "allow": [
      "Bash(export AWS_ACCESS_KEY_ID=\"ASIAIOSFODNN7EXAMPLE\")"
    ]
  }
}
JSON

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$TEST_TEMP_DIR" --strict
    assert_failure
    assert_output --partial "AWS Access Key"
}

@test "security-credential-scan.sh emits valid JSON for quote-heavy .claude settings" {
    mkdir -p "$TEST_TEMP_DIR/.claude"
    cat > "$TEST_TEMP_DIR/.claude/settings.local.json" <<'JSON'
{
  "permissions": {
    "allow": [
      "Bash(export AWS_ACCESS_KEY_ID=\"ASIAIOSFODNN7EXAMPLE\")"
    ]
  }
}
JSON

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$TEST_TEMP_DIR" --json
    assert_success
    # Output must parse as JSON despite escaped quotes in the finding
    echo "$output" | jq -e '.critical_count >= 1' >/dev/null
}

@test "security-credential-scan.sh ignores public Supabase local-dev demo key" {
    mkdir -p "$TEST_TEMP_DIR/.claude"
    cat > "$TEST_TEMP_DIR/.claude/settings.local.json" <<'JSON'
{
  "permissions": {
    "allow": [
      "Bash(SUPABASE_SERVICE_ROLE_KEY=\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSJ9.demo\" supabase status)"
    ]
  }
}
JSON

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$TEST_TEMP_DIR" --strict
    assert_success
    assert_output --partial "No credentials found"
}

@test "security-credential-scan.sh ignores Nix flake.lock rev hashes" {
    mkdir -p "$TEST_TEMP_DIR/nix"
    cat > "$TEST_TEMP_DIR/nix/flake.lock" <<'JSON'
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "rev": "0123456789abcdef0123456789abcdef01234567",
        "narHash": "sha256-0123456789abcdef0123456789abcdef0123456789abc="
      }
    }
  }
}
JSON

    run "$REPO_ROOT/script/security-credential-scan.sh" --path "$TEST_TEMP_DIR" --strict
    assert_success
    assert_output --partial "No credentials found"
}
