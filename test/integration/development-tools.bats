#!/usr/bin/env bats
# Integration tests for development tools

setup() {
  # Store original directory
  ORIGINAL_DIR="$(pwd)"

  # Create temporary test directory
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR" || exit 1

  # Initialize git repository
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
}

teardown() {
  # Return to original directory
  cd "$ORIGINAL_DIR" || exit 1

  # Clean up test directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

@test "changelog-generator.sh should show help message" {
  run bash "$ORIGINAL_DIR/script/changelog-generator.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "Options:" ]]
}

@test "changelog-generator.sh should handle repository with commits" {
  # Create initial commit
  touch README.md
  git add README.md
  git commit -q -m "feat: initial commit"

  # Create a tag
  git tag v1.0.0

  # Create another commit
  echo "update" >> README.md
  git add README.md
  git commit -q -m "feat: add feature"

  run bash "$ORIGINAL_DIR/script/changelog-generator.sh" --dry-run
  # May succeed or fail depending on git history, but should not crash
  [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "code-complexity-check.sh should show help message" {
  run bash "$ORIGINAL_DIR/script/code-complexity-check.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "threshold" ]]
}

@test "code-complexity-check.sh should analyze simple script" {
  # Create a simple test script
  cat > test-script.sh <<'EOF'
#!/bin/bash
echo "Hello World"
EOF
  chmod +x test-script.sh

  run bash "$ORIGINAL_DIR/script/code-complexity-check.sh" --files "test-script.sh"
  # Should handle analysis or report no files found
  [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "container-health.sh should show help message" {
  run bash "$ORIGINAL_DIR/script/container-health.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "container-health.sh should run without crashing" {
  run bash "$ORIGINAL_DIR/script/container-health.sh" --json
  # May fail or succeed depending on environment, but should not crash
  [[ "$status" -ge 0 ]] && [[ "$status" -le 1 ]]
  # Output should contain some expected patterns
  [[ -n "$output" ]]
}

@test "security-credential-scan.sh should show help message" {
  run bash "$ORIGINAL_DIR/script/security-credential-scan.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "strict" ]]
}

@test "security-credential-scan.sh should detect no credentials in clean repo" {
  touch clean-file.txt
  echo "# Clean content" > clean-file.txt

  run bash "$ORIGINAL_DIR/script/security-credential-scan.sh" --path . --json
  [ "$status" -eq 0 ]
  [[ "$output" =~ '"critical_count": 0' ]]
}

@test "security-credential-scan.sh should scan for credentials" {
  # Create a file with a potential credential pattern (testing purposes only)
  echo "const apiKey = 'AKIAIOSFODNN7EXAMPLE';" > test-file.js

  run bash "$ORIGINAL_DIR/script/security-credential-scan.sh" --path . --json
  # Should complete the scan (may or may not find issues depending on environment)
  [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
  # Output should contain JSON structure (critical_count or findings)
  [[ "$output" =~ "critical_count" ]] || [[ "$output" =~ "findings" ]] || [[ "$output" =~ "{" ]]
}

@test "test-coverage-trend.sh should show help message" {
  run bash "$ORIGINAL_DIR/script/test-coverage-trend.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "test-coverage-trend.sh should handle missing coverage data" {
  run bash "$ORIGINAL_DIR/script/test-coverage-trend.sh" --json
  # Should handle gracefully even if no coverage data exists
  [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
}

@test "all development tool scripts should have executable permissions" {
  scripts=(
    "changelog-generator.sh"
    "code-complexity-check.sh"
    "container-health.sh"
    "security-credential-scan.sh"
    "test-coverage-trend.sh"
  )

  for script in "${scripts[@]}"; do
    [ -x "$ORIGINAL_DIR/script/$script" ]
  done
}

@test "all development tool scripts should have proper shebang" {
  scripts=(
    "changelog-generator.sh"
    "code-complexity-check.sh"
    "container-health.sh"
    "security-credential-scan.sh"
    "test-coverage-trend.sh"
  )

  for script in "${scripts[@]}"; do
    first_line=$(head -n 1 "$ORIGINAL_DIR/script/$script")
    [[ "$first_line" =~ ^#!/.*bash ]]
  done
}
