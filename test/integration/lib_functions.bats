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

@test "project-detect.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/lib/project-detect.sh"
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

@test "config.sh defines managed import/export repository directories" {
  grep -q "CONFIG_MANAGED_REPO_DIRS" "${REPO_ROOT}/script/lib/config.sh"
  grep -q "config::ensure_managed_repo_dirs()" "${REPO_ROOT}/script/lib/config.sh"
}

@test "config::ensure_managed_repo_dirs creates managed directories" {
  source "${REPO_ROOT}/script/lib/config.sh"

  local target="${TEST_TEMP_DIR}/managed-repo"
  config::ensure_managed_repo_dirs "$target"

  [ -d "$target/brew" ]
  [ -d "$target/vscode" ]
  [ -d "$target/git" ]
  [ -d "$target/npm" ]
  [ -d "$target/.zsh" ]
  [ -d "$target/dot" ]
  [ -d "$target/.claude" ]
  [ -d "$target/.codex" ]
  [ -d "$target/.cursor" ]
  [ -d "$target/.gemini" ]
}

@test "export.sh uses shared managed directory helper" {
  grep -q "config::ensure_managed_repo_dirs" "${REPO_ROOT}/script/export.sh"
  ! grep -q 'mkdir -p "$REPO_PATH/brew"' "${REPO_ROOT}/script/export.sh"
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

# ============================================================================
# platform.sh runtime behaviour tests
# ============================================================================

@test "platform.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/lib/platform.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "platform::detect_os returns a recognised OS name" {
  # Each @test runs in a subshell so PLATFORM_LIB_SOURCED is unset
  source "${REPO_ROOT}/script/lib/platform.sh"

  local result
  result="$(platform::detect_os)"
  [[ "$result" == "linux" || "$result" == "darwin" || "$result" == "windows" || "$result" == "unknown" ]]
}

@test "platform::detect_os returns linux or darwin in CI" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  local result
  result="$(platform::detect_os)"
  # GitHub Actions and DevContainers always run on linux or darwin
  [[ "$result" == "linux" || "$result" == "darwin" ]]
}

@test "PLATFORM_OS is set after sourcing platform.sh" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  [ -n "$PLATFORM_OS" ]
}

@test "platform::is_supported returns true when OS is linux or darwin" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  # CI / DevContainer always runs on a supported OS
  platform::is_supported
}

@test "platform::is_linux and platform::is_darwin are mutually exclusive" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  # At most one of them should be true
  local is_linux=0
  local is_darwin=0
  platform::is_linux && is_linux=1 || true
  platform::is_darwin && is_darwin=1 || true

  [ $(( is_linux + is_darwin )) -le 1 ]
}

@test "platform::is_linux returns true on Linux" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  if [[ "$(uname -s)" == "Linux" ]]; then
    platform::is_linux
  else
    skip "Not running on Linux"
  fi
}

@test "platform::is_darwin returns true on macOS" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  if [[ "$(uname -s)" == "Darwin" ]]; then
    platform::is_darwin
  else
    skip "Not running on macOS"
  fi
}

@test "platform::is_devcontainer is callable without error" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  # The function reads env vars; just check it exits cleanly
  run platform::is_devcontainer
  # Exit code 0 (in devcontainer) or 1 (not in devcontainer) are both valid
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "platform::is_windows returns false on Linux/macOS" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  if [[ "$(uname -s)" == "Linux" || "$(uname -s)" == "Darwin" ]]; then
    ! platform::is_windows
  else
    skip "Not running on Linux or macOS"
  fi
}

@test "platform::run_task is a no-op for an undefined task" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  # run_task should exit 0 even when the task function does not exist
  run platform::run_task "__nonexistent_task__"
  [ "$status" -eq 0 ]
}

@test "platform::assert_supported passes on supported OS" {
  source "${REPO_ROOT}/script/lib/platform.sh"

  run platform::assert_supported
  [ "$status" -eq 0 ]
}

# ============================================================================
# project-detect.sh runtime behaviour tests
# ============================================================================

@test "project::has_file_matching returns true when file exists" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/proj-a"
  touch "${TEST_TEMP_DIR}/proj-a/next.config.js"

  project::has_file_matching "${TEST_TEMP_DIR}/proj-a" "next.config.*"
}

@test "project::has_file_matching returns false when file does not exist" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/proj-empty"

  run project::has_file_matching "${TEST_TEMP_DIR}/proj-empty" "next.config.*"
  [ "$status" -ne 0 ]
}

@test "project::detect_package_manager detects npm from package-lock.json" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/pm-npm"
  echo '{}' > "${TEST_TEMP_DIR}/pm-npm/package-lock.json"

  result="$(project::detect_package_manager "${TEST_TEMP_DIR}/pm-npm")"
  [ "$result" = "npm" ]
}

@test "project::detect_package_manager detects pnpm from pnpm-lock.yaml" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/pm-pnpm"
  touch "${TEST_TEMP_DIR}/pm-pnpm/pnpm-lock.yaml"

  result="$(project::detect_package_manager "${TEST_TEMP_DIR}/pm-pnpm")"
  [ "$result" = "pnpm" ]
}

@test "project::detect_package_manager detects yarn from yarn.lock" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/pm-yarn"
  touch "${TEST_TEMP_DIR}/pm-yarn/yarn.lock"

  result="$(project::detect_package_manager "${TEST_TEMP_DIR}/pm-yarn")"
  [ "$result" = "yarn" ]
}

@test "project::detect_package_manager returns unknown without lockfiles" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/pm-none"

  result="$(project::detect_package_manager "${TEST_TEMP_DIR}/pm-none")"
  [ "$result" = "unknown" ]
}

@test "project::detect_type detects nextjs from next.config file" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/type-nextjs"
  touch "${TEST_TEMP_DIR}/type-nextjs/next.config.js"
  echo '{"name":"test"}' > "${TEST_TEMP_DIR}/type-nextjs/package.json"

  result="$(project::detect_type "${TEST_TEMP_DIR}/type-nextjs")"
  [ "$result" = "nextjs" ]
}

@test "project::detect_type detects flutter from pubspec.yaml" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/type-flutter"
  touch "${TEST_TEMP_DIR}/type-flutter/pubspec.yaml"

  result="$(project::detect_type "${TEST_TEMP_DIR}/type-flutter")"
  [ "$result" = "flutter" ]
}

@test "project::detect_type detects nodejs from bare package.json" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/type-nodejs"
  echo '{"name":"test","dependencies":{}}' > "${TEST_TEMP_DIR}/type-nodejs/package.json"

  result="$(project::detect_type "${TEST_TEMP_DIR}/type-nodejs")"
  [ "$result" = "nodejs" ]
}

@test "project::detect_type returns unknown when no project file found" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/type-unknown"

  result="$(project::detect_type "${TEST_TEMP_DIR}/type-unknown")"
  [ "$result" = "unknown" ]
}

@test "project::name returns directory basename" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/myproject"

  result="$(project::name "${TEST_TEMP_DIR}/myproject")"
  [ "$result" = "myproject" ]
}

@test "project::has_package_dependency detects dependency in dependencies section" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/dep-test"
  echo '{"name":"test","dependencies":{"react":"^18.0.0"}}' \
    > "${TEST_TEMP_DIR}/dep-test/package.json"

  project::has_package_dependency "${TEST_TEMP_DIR}/dep-test" "react"
}

@test "project::has_package_dependency detects dependency in devDependencies section" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/dep-dev"
  echo '{"name":"test","devDependencies":{"jest":"^30.0.0"}}' \
    > "${TEST_TEMP_DIR}/dep-dev/package.json"

  project::has_package_dependency "${TEST_TEMP_DIR}/dep-dev" "jest"
}

@test "project::has_package_dependency returns false for missing dependency" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/dep-missing"
  echo '{"name":"test","dependencies":{}}' \
    > "${TEST_TEMP_DIR}/dep-missing/package.json"

  run project::has_package_dependency "${TEST_TEMP_DIR}/dep-missing" "nonexistent-pkg"
  [ "$status" -ne 0 ]
}

@test "project::has_package_field detects bin field" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/field-bin"
  echo '{"name":"test","bin":{"cli":"index.js"}}' \
    > "${TEST_TEMP_DIR}/field-bin/package.json"

  project::has_package_field "${TEST_TEMP_DIR}/field-bin" "bin"
}

@test "project::has_package_field returns false for missing field" {
  source "${REPO_ROOT}/script/lib/project-detect.sh"

  mkdir -p "${TEST_TEMP_DIR}/field-none"
  echo '{"name":"test"}' > "${TEST_TEMP_DIR}/field-none/package.json"

  run project::has_package_field "${TEST_TEMP_DIR}/field-none" "bin"
  [ "$status" -ne 0 ]
}
