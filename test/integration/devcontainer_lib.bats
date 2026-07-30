#!/usr/bin/env bats

# Integration tests for script/lib/devcontainer.sh
#
# devcontainer.sh bootstraps git identity and secret-backend configuration
# on every DevContainer/Codespaces start, but had no test coverage.

load ../test_helper/test_helper

@test "devcontainer.sh script exists and is executable" {
  local script="${REPO_ROOT}/script/lib/devcontainer.sh"
  assert_file_exists "$script"
  [ -x "$script" ]
}

@test "devcontainer::is_active returns false when PLATFORM_IN_DEVCONTAINER is unset" {
  source "${REPO_ROOT}/script/lib/devcontainer.sh"
  unset PLATFORM_IN_DEVCONTAINER

  run devcontainer::is_active
  [ "$status" -ne 0 ]
}

@test "devcontainer::is_active returns true when PLATFORM_IN_DEVCONTAINER=true" {
  source "${REPO_ROOT}/script/lib/devcontainer.sh"
  PLATFORM_IN_DEVCONTAINER=true

  run devcontainer::is_active
  [ "$status" -eq 0 ]
}

@test "devcontainer::is_active returns false when PLATFORM_IN_DEVCONTAINER=false" {
  source "${REPO_ROOT}/script/lib/devcontainer.sh"
  PLATFORM_IN_DEVCONTAINER=false

  run devcontainer::is_active
  [ "$status" -ne 0 ]
}

@test "devcontainer::configure_git_identity sets git user name and email" {
  source "${REPO_ROOT}/script/lib/devcontainer.sh"

  export HOME="${TEST_TEMP_DIR}"

  devcontainer::configure_git_identity "Test User" "test@example.com"

  [ "$(git config --global user.name)" = "Test User" ]
  [ "$(git config --global user.email)" = "test@example.com" ]
}

@test "devcontainer::ensure_secret_backend is a no-op for provider=none" {
  source "${REPO_ROOT}/script/lib/devcontainer.sh"

  run devcontainer::ensure_secret_backend "none"
  [ "$status" -eq 0 ]
}

@test "devcontainer::ensure_secret_backend is a no-op for an empty provider" {
  source "${REPO_ROOT}/script/lib/devcontainer.sh"

  run devcontainer::ensure_secret_backend ""
  [ "$status" -eq 0 ]
}

@test "devcontainer::ensure_secret_backend rejects unsupported providers" {
  source "${REPO_ROOT}/script/lib/devcontainer.sh"

  run devcontainer::ensure_secret_backend "bitwarden"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unsupported secret provider: bitwarden"* ]]
}
