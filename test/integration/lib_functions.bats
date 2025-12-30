#!/usr/bin/env bats

# Integration tests for library functions (config.sh and errors.sh)

load ../test_helper/test_helper

@test "config.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/lib/config.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "errors.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/lib/errors.sh"
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

@test "errors.sh defines errors::fatal function" {
  grep -q "errors::fatal()" "${REPO_ROOT}/script/lib/errors.sh"
}

@test "errors.sh defines errors::warn function" {
  grep -q "errors::warn()" "${REPO_ROOT}/script/lib/errors.sh"
}

@test "errors.sh defines errors::info function" {
  grep -q "errors::info()" "${REPO_ROOT}/script/lib/errors.sh"
}

@test "errors.sh defines errors::success function" {
  grep -q "errors::success()" "${REPO_ROOT}/script/lib/errors.sh"
}

@test "errors.sh defines errors::require_command function" {
  grep -q "errors::require_command()" "${REPO_ROOT}/script/lib/errors.sh"
}

@test "errors.sh defines errors::require_file function" {
  grep -q "errors::require_file()" "${REPO_ROOT}/script/lib/errors.sh"
}

@test "errors.sh defines errors::require_directory function" {
  grep -q "errors::require_directory()" "${REPO_ROOT}/script/lib/errors.sh"
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

@test "errors::require_command succeeds for existing command" {
  # Source errors.sh
  source "${REPO_ROOT}/script/lib/errors.sh"

  # Test with 'ls' which should always exist
  run errors::require_command ls
  [ "$status" -eq 0 ]
}

@test "errors::info outputs to stdout" {
  source "${REPO_ROOT}/script/lib/errors.sh"

  run errors::info "Test message"
  [ "$status" -eq 0 ]
  [[ "$output" == *"INFO: Test message"* ]]
}

@test "errors::warn outputs to stderr" {
  source "${REPO_ROOT}/script/lib/errors.sh"

  run errors::warn "Test warning"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARNING: Test warning"* ]]
}

@test "errors::success outputs success message" {
  source "${REPO_ROOT}/script/lib/errors.sh"

  run errors::success "Operation completed"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Operation completed"* ]]
}
