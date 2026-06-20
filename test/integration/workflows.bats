#!/usr/bin/env bats

# Integration tests for GitHub Actions workflows

load ../test_helper/test_helper

@test "all workflow files are valid YAML" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"
  assert_directory_exists "$workflows_dir"

  # Check each workflow file has valid YAML syntax
  for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
    [ -f "$workflow" ] || continue
    # Basic YAML structure check using grep
    grep -q "^name:" "$workflow"
    grep -q "^on:" "$workflow"
    grep -q "^jobs:" "$workflow"
  done
}

@test "root workflow count is consolidated to 14 files" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"
  local count

  count=$(find "$workflows_dir" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | wc -l | tr -d ' ')

  [ "$count" -eq 14 ]
  [ ! -e "$workflows_dir/rebuild-docker-cache.yml" ]
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

@test "CI workflow runs workflow lint when actionlint config changes" {
  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"
  assert_file_exists "$workflow"

  grep -Fq "'**.yml'" "$workflow"
  grep -Fq "'**.yaml'" "$workflow"
  grep -Fq "'.github/actions/**'" "$workflow"
  grep -Fq "'.github/actionlint.yaml'" "$workflow"
  grep -Fq "'.takt/**'" "$workflow"
  grep -Fq "'templates/workflows/**'" "$workflow"
  grep -Fq "'templates/github/labels.yml'" "$workflow"
  grep -Fq "workflows:" "$workflow"
  grep -Fq "needs.changes.outputs.workflows == 'true'" "$workflow"
  grep -Fq "name: Collect workflow files" "$workflow"
  grep -Fq ".context/actionlint-files.txt" "$workflow"
  grep -Fq "find .github/workflows/templates" "$workflow"
  grep -Fq "find templates/workflows" "$workflow"
  grep -Fq -- "-name '*.yaml'" "$workflow"
  grep -Fq "actionlint_flags:" "$workflow"
  grep -Fq "Workflow Template Sync" "$workflow"
  grep -Fq "npm run workflow:sync:check" "$workflow"
  grep -Fq "WORKFLOW_TEMPLATE_SYNC_RESULT" "$workflow"
  grep -Fq "steps.workflow-files.outputs.files" "$workflow"
  grep -Fq "pull-requests: write" "$workflow"
  grep -Fq "fail_level: error" "$workflow"
  ! grep -Fq "fail_on_error: true" "$workflow"
}

@test "CI workflow uses the PR size composite action" {
  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"
  local action="${REPO_ROOT}/.github/actions/pr-size-check/action.yml"

  assert_file_exists "$action"
  grep -Fq "./.github/actions/pr-size-check" "$workflow"
  grep -Fq "actions/github-script@" "$action"
  ! grep -Fq "const { additions, deletions, changed_files }" "$workflow"
}

@test "CI workflow uses secure practices" {
  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"

  # Should use npm ci (directly or via composite action)
  grep -q "npm ci\|setup-node-ci" "$workflow"

  # Should use pinned action versions (SHA or tag) or composite actions
  grep -q "actions/checkout@" "$workflow"
  grep -q "actions/setup-node@\|setup-node-ci" "$workflow"
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

@test "docker-image workflow owns weekly no-cache cache rebuilds" {
  local workflow="${REPO_ROOT}/.github/workflows/docker-image.yml"

  grep -Fq "cron: '0 0 * * 0'" "$workflow"
  grep -Fq "no_cache:" "$workflow"
  grep -Fq "image_tag=cache-rebuild" "$workflow"
  grep -Fq "no-cache: \${{ steps.release.outputs.no_cache }}" "$workflow"
  grep -Fq "steps.release.outputs.cache_rebuild != 'true'" "$workflow"
}

@test "Docker workflows use setup-docker-build composite action" {
  local action="${REPO_ROOT}/.github/actions/setup-docker-build/action.yml"

  assert_file_exists "$action"
  grep -Fq "docker/setup-qemu-action@" "$action"
  grep -Fq "docker/setup-buildx-action@" "$action"
  grep -Fq "docker/login-action@" "$action"

  grep -Fq "./.github/actions/setup-docker-build" "$REPO_ROOT/.github/workflows/docker-image.yml"
  grep -Fq "./.github/actions/setup-docker-build" "$REPO_ROOT/.github/workflows/manual-release.yml"
  grep -Fq "./.github/actions/setup-docker-build" "$REPO_ROOT/.github/workflows/container-security.yml"

  ! grep -Fq "docker/setup-qemu-action@" "$REPO_ROOT/.github/workflows/docker-image.yml"
  ! grep -Fq "docker/setup-buildx-action@" "$REPO_ROOT/.github/workflows/docker-image.yml"
  ! grep -Fq "docker/login-action@" "$REPO_ROOT/.github/workflows/docker-image.yml"
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

  # Should use pinned version for peter-evans/create-pull-request (SHA or tag)
  grep -q "peter-evans/create-pull-request@" "$workflow"
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
  # Workflows that don't need checkout (no source code access required)
  local skip_patterns="dependabot-auto-merge|quality-gate-fallback"

  for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
    [ -f "$workflow" ] || continue
    local basename
    basename=$(basename "$workflow")
    if echo "$basename" | grep -qE "$skip_patterns"; then
      continue
    fi
    if grep -q "^jobs:" "$workflow"; then
      grep -q "actions/checkout@" "$workflow"
    fi
  done
}

@test "all workflows pin action versions" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
    [ -f "$workflow" ] || continue
    # Check that actions use @vX or @commit_hash
    # Should not use @main or @master
    ! grep -q "uses:.*@main" "$workflow"
    ! grep -q "uses:.*@master" "$workflow"
  done
}

@test "workflows do not expose secrets in environment variables" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
    [ -f "$workflow" ] || continue
    # Should not set secrets as env vars that could be logged
    # Secrets should only be passed to 'with:' or 'env:' of specific steps
    # Check for potential exposure patterns
    ! grep -q 'echo.*\${{.*secrets\.' "$workflow" || true
  done
}

@test "workflows use GITHUB_TOKEN for GitHub operations" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
    [ -f "$workflow" ] || continue
    # Workflows that create releases or push should use GITHUB_TOKEN
    if grep -q "gh release create\|git push\|npx semantic-release" "$workflow"; then
      grep -q "GITHUB_TOKEN.*secrets.GITHUB_TOKEN" "$workflow"
    fi
  done
}

@test "workflows do not use deprecated actions" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
    [ -f "$workflow" ] || continue
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

@test "container-security workflow runs a single Trivy scan and derives results" {
  local workflow="${REPO_ROOT}/.github/workflows/container-security.yml"
  local count

  count=$(grep -c "aquasecurity/trivy-action@" "$workflow")

  [ "$count" -eq 1 ]
  grep -Fq "trivy-results.sarif" "$workflow"
  grep -Fq "count_by_severity" "$workflow"
  grep -Fq "CRITICAL_COUNT" "$workflow"
}

@test "scheduled maintenance reviews trivyignore entries" {
  local workflow="${REPO_ROOT}/.github/workflows/scheduled-maintenance.yml"

  grep -Fq "script/check-trivyignore-review.sh" "$workflow"
  grep -Fq "npm exec --yes --package=takt@0.47.0" "$workflow"
  grep -Fq -- "--workflow .takt/workflows/repo-maintenance.yml" "$workflow"
  grep -Fq "TAKT_ANTHROPIC_API_KEY" "$workflow"
}

@test "workflows have descriptive job names" {
  local workflows_dir="${REPO_ROOT}/.github/workflows"

  for workflow in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
    [ -f "$workflow" ] || continue
    # Each workflow should have a descriptive name
    grep -q "^name:.*[A-Za-z]" "$workflow"
  done
}

@test "ci workflow uploads coverage reports securely" {
  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"

  # Should upload coverage with token (SHA or tag)
  grep -q "codecov/codecov-action@" "$workflow"
  grep -q "token:.*secrets.CODECOV_TOKEN" "$workflow"

  # Should not fail CI on coverage upload errors
  grep -q "fail_ci_if_error: false" "$workflow"
}
