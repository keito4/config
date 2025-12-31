#!/usr/bin/env bats

# Integration tests for library functions (config.sh and output.sh)

load ../test_helper/test_helper

@test "config.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/lib/config.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "output.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/lib/output.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "config.sh uses strict error handling" {
  grep -q "set -euo pipefail" "${REPO_ROOT}/script/lib/config.sh"
}

@test "config.sh defines config::import_claude function" {
  grep -q "config::import_claude()" "${REPO_ROOT}/script/lib/config.sh"
}

@test "config.sh defines config::export_claude function" {
  grep -q "config::export_claude()" "${REPO_ROOT}/script/lib/config.sh"
}

@test "config.sh defines config::filter_gitconfig function" {
  grep -q "config::filter_gitconfig()" "${REPO_ROOT}/script/lib/config.sh"
}

@test "config.sh defines config::filter_credentials function" {
  grep -q "config::filter_credentials()" "${REPO_ROOT}/script/lib/config.sh"
}

# Output function tests (consolidated from errors.sh)
@test "output.sh defines output::fatal function" {
  grep -q "output::fatal()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh defines output::warning function" {
  grep -q "output::warning()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh defines output::info function" {
  grep -q "output::info()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh defines output::success function" {
  grep -q "output::success()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh defines output::require_command function" {
  grep -q "output::require_command()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh defines output::require_file function" {
  grep -q "output::require_file()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh defines output::require_directory function" {
  grep -q "output::require_directory()" "${REPO_ROOT}/script/lib/output.sh"
}

# Backward compatibility: errors:: namespace aliases
@test "output.sh provides errors::fatal alias" {
  grep -q "errors::fatal()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh provides errors::warn alias" {
  grep -q "errors::warn()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "output.sh provides errors::require_command alias" {
  grep -q "errors::require_command()" "${REPO_ROOT}/script/lib/output.sh"
}

@test "config::filter_gitconfig filters personal information" {
  # Create a test gitconfig with personal info
  local test_input="${TEST_TEMP_DIR}/test.gitconfig"
  local test_output="${TEST_TEMP_DIR}/filtered.gitconfig"

  cat > "$test_input" << 'EOF'
[user]
	name = John Doe
	email = john@example.com
	signingkey = ssh-ed25519 AAAAC3...
[core]
	editor = vim
EOF

  # Source config.sh and run filter function
  source "${REPO_ROOT}/script/lib/config.sh"
  config::filter_gitconfig "$test_input" "$test_output"

  # Verify personal info is commented out
  grep -q "# name =" "$test_output"
  grep -q "# email =" "$test_output"
  grep -q "# signingkey =" "$test_output"

  # Verify core.editor is preserved
  grep -q "editor = vim" "$test_output"
}

@test "config::filter_credentials removes sensitive tokens" {
  # Create a test file with credentials
  local test_input="${TEST_TEMP_DIR}/test.zshrc"
  local test_output="${TEST_TEMP_DIR}/filtered.zshrc"

  cat > "$test_input" << 'EOF'
export PATH="/usr/local/bin:$PATH"
export NPM_TOKEN="npm_abcd1234"
export BUNDLE_RUBYGEMS__GEM__FURY__IO="token123"
alias ll='ls -la'
EOF

  # Source config.sh and run filter function
  source "${REPO_ROOT}/script/lib/config.sh"
  config::filter_credentials "$test_input" "$test_output"

  # Verify credentials are removed
  ! grep -q "NPM_TOKEN" "$test_output"
  ! grep -q "BUNDLE_RUBYGEMS" "$test_output"

  # Verify safe content is preserved
  grep -q 'export PATH="/usr/local/bin:$PATH"' "$test_output"
  grep -q "alias ll=" "$test_output"
}

@test "output::require_command succeeds for existing command" {
  # Source output.sh
  source "${REPO_ROOT}/script/lib/output.sh"

  # Test with 'ls' which should always exist
  run output::require_command ls
  [ "$status" -eq 0 ]
}

@test "output::info outputs to stdout" {
  source "${REPO_ROOT}/script/lib/output.sh"

  run output::info "Test message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"INFO"* ]]
  [[ "$output" == *"Test message"* ]]
}

@test "output::warning outputs warning message" {
  source "${REPO_ROOT}/script/lib/output.sh"

  run output::warning "Test warning"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test warning"* ]]
}

@test "output::success outputs success message" {
  source "${REPO_ROOT}/script/lib/output.sh"

  run output::success "Operation completed"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation completed"* ]]
}

# Backward compatibility: test errors:: aliases work
@test "errors:: aliases work through output.sh" {
  source "${REPO_ROOT}/script/lib/output.sh"

  run errors::require_command ls
  [ "$status" -eq 0 ]

  run errors::info "Test info"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test info"* ]]

  run errors::success "Test success"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test success"* ]]
}
