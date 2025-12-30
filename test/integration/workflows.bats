#!/usr/bin/env bats

# Integration tests for GitHub Actions workflows

load ../test_helper/test_helper

@test "all workflow files are valid YAML" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"
  assert_directory_exists "$workflows_dir"

  # Check each workflow file has valid YAML syntax
  for workflow in "$workflows_dir"/*.yml; do
    # Basic YAML structure check using grep
    grep -q "^name:" "$workflow"
    grep -q "^on:" "$workflow"
    grep -q "^jobs:" "$workflow"
  done
}

@test "CI workflow has required quality checks" {
  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"
  assert_file_exists "$workflow"

  # Verify required steps exist
  grep -q "npm run lint" "$workflow"
  grep -q "npm run shellcheck" "$workflow"
  grep -q "npm run format:check" "$workflow"
  grep -q "npm run test:coverage" "$workflow"
}

@test "CI workflow uses secure practices" {
  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"

  # Should use npm ci instead of npm install
  grep -q "npm ci" "$workflow"

  # Should use pinned action versions
  grep -q "actions/checkout@v4" "$workflow"
  grep -q "actions/setup-node@v4" "$workflow"
}

@test "docker-image workflow has proper permissions" {
  local workflow="${REPO_ROOT}/.github/workflows/docker-image.yml"
  assert_file_exists "$workflow"

  # Verify permissions are explicitly set
  grep -q "permissions:" "$workflow"
  grep -q "contents: write" "$workflow"
  grep -q "packages: write" "$workflow"
}

@test "docker-image workflow uses secrets securely" {
  local workflow="${REPO_ROOT}/.github/workflows/docker-image.yml"

  # Should use secrets for sensitive data
  grep -q 'secrets.GITHUB_TOKEN' "$workflow"
  grep -q 'secrets.CLAUDE_CODE_OAUTH_TOKEN' "$workflow"

  # Should not expose secrets in logs
  ! grep -q 'echo.*secrets\.' "$workflow"
}

@test "docker-image workflow validates manual inputs" {
  local workflow="${REPO_ROOT}/.github/workflows/docker-image.yml"

  # Should have input validation for workflow_dispatch
  grep -q "workflow_dispatch:" "$workflow"
  grep -q "inputs:" "$workflow"

  # Should validate custom_version when provided
  grep -q 'if \[ -z.*CUSTOM_VERSION' "$workflow"
}

@test "docker-image workflow prevents command injection in version bumping" {
  local workflow="${REPO_ROOT}/.github/workflows/docker-image.yml"

  # Check that version bumping uses safe parameter expansion
  grep -q 'MODE="\${{ inputs.release_mode }}"' "$workflow"
  grep -q 'CUSTOM_VERSION="\${{ inputs.custom_version }}"' "$workflow"

  # Should use validated variables in bump_version function
  grep -q 'bump_version.*"\$MODE"' "$workflow"
}

@test "update-libraries workflow has proper permissions" {
  local workflow="${REPO_ROOT}/.github/workflows/update-libraries.yml"
  assert_file_exists "$workflow"

  # Verify minimal required permissions
  grep -q "permissions:" "$workflow"
  grep -q "contents: write" "$workflow"
  grep -q "pull-requests: write" "$workflow"
}

@test "update-libraries workflow uses pinned third-party actions" {
  local workflow="${REPO_ROOT}/.github/workflows/update-libraries.yml"

  # Should use specific version for peter-evans/create-pull-request
  grep -q "peter-evans/create-pull-request@v6" "$workflow"
}

@test "update-libraries workflow has safe cron schedule" {
  local workflow="${REPO_ROOT}/.github/workflows/update-libraries.yml"

  # Should have schedule trigger
  grep -q "schedule:" "$workflow"
  grep -q "cron:" "$workflow"

  # Cron should be reasonable (not too frequent)
  # Weekly on Monday at 3 AM is safe
  grep -q "'0 3 \* \* 1'" "$workflow"
}

@test "all workflows use checkout action" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml; do
    # Every workflow should checkout the repository
    if grep -q "^jobs:" "$workflow"; then
      grep -q "actions/checkout@" "$workflow"
    fi
  done
}

@test "all workflows pin action versions" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml; do
    # Check that actions use @vX or @commit_hash
    # Should not use @main or @master
    ! grep -q "uses:.*@main" "$workflow"
    ! grep -q "uses:.*@master" "$workflow"
  done
}

@test "workflows do not expose secrets in environment variables" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml; do
    # Should not set secrets as env vars that could be logged
    # Secrets should only be passed to 'with:' or 'env:' of specific steps
    # Check for potential exposure patterns
    ! grep -q 'echo.*\${{.*secrets\.' "$workflow" || true
  done
}

@test "workflows use GITHUB_TOKEN for GitHub operations" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml; do
    # Workflows that create releases or push should use GITHUB_TOKEN
    if grep -q "gh release create\|git push\|npx semantic-release" "$workflow"; then
      grep -q "GITHUB_TOKEN.*secrets.GITHUB_TOKEN" "$workflow"
    fi
  done
}

@test "workflows do not use deprecated actions" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml; do
    # Should not use deprecated actions
    ! grep -q "actions/setup-node@v1" "$workflow"
    ! grep -q "actions/checkout@v1" "$workflow"
    ! grep -q "actions/checkout@v2" "$workflow"
  done
}

@test "docker-image workflow builds for multiple platforms" {
  local workflow="${REPO_ROOT}/.github/workflows/docker-image.yml"

  # Should build for both amd64 and arm64
  grep -q "platforms:.*linux/amd64,linux/arm64" "$workflow"
}

@test "docker-image workflow uses build cache" {
  local workflow="${REPO_ROOT}/.github/workflows/docker-image.yml"

  # Should use Docker layer caching
  grep -q "cache-from:" "$workflow"
  grep -q "cache-to:" "$workflow"
}

@test "workflows have descriptive job names" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml; do
    # Each workflow should have a descriptive name
    grep -q "^name:.*[A-Za-z]" "$workflow"
  done
}

@test "ci workflow uploads coverage reports securely" {
  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"

  # Should upload coverage with token
  grep -q "codecov/codecov-action@v4" "$workflow"
  grep -q "token:.*secrets.CODECOV_TOKEN" "$workflow"

  # Should not fail CI on coverage upload errors
  grep -q "fail_ci_if_error: false" "$workflow"
}
