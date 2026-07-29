#!/usr/bin/env bats

# Integration tests for script/setup-team-protection.sh
# (script/lib/setup_team_protection.sh).
#
# This script configures GitHub branch protection, repository settings, and
# security features for a repository. Prior to this test file it was only
# covered by string-matching assertions (grep for function names), with no
# functional coverage of the branch-type presets, protection-level overlay,
# or argument validation. These tests exercise the --dry-run path against a
# mocked `gh` CLI so no real GitHub API calls are made and nothing mutates
# the target repository.

load ../test_helper/test_helper

# Installs a fake `gh` binary on PATH that answers just enough of the `gh`
# surface used by setup-team-protection.sh to drive it through --dry-run:
#   - `gh auth status`                              -> success
#   - `gh api repos/OWNER/REPO/branches/BRANCH`      -> branch exists
#   - `gh api repos/OWNER/REPO/contents/...`         -> quality-gate fallback present
#   - `gh api repos/OWNER/REPO --jq '.permissions...'` -> prints admin flag
# Behavior is tunable per test via MOCK_GH_ADMIN / MOCK_GH_BRANCH_EXIT /
# MOCK_GH_FALLBACK_EXIT environment variables.
setup_fake_gh() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "auth" ] && [ "$2" = "status" ]; then
  exit 0
fi
if [ "$1" = "api" ]; then
  path="$2"
  case "$path" in
    */branches/*)
      exit "${MOCK_GH_BRANCH_EXIT:-0}"
      ;;
    */contents/*)
      exit "${MOCK_GH_FALLBACK_EXIT:-0}"
      ;;
    *)
      echo "${MOCK_GH_ADMIN:-true}"
      exit 0
      ;;
  esac
fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/gh"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

@test "setup-team-protection.sh script exists and is executable" {
  assert_file_exists "${REPO_ROOT}/script/setup-team-protection.sh"
  [ -x "${REPO_ROOT}/script/setup-team-protection.sh" ]
}

@test "--help prints usage without requiring a repository or gh CLI" {
  run "${REPO_ROOT}/script/setup-team-protection.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Team Repository Protection Setup"* ]]
  [[ "$output" == *"--dry-run"* ]]
}

@test "rejects an invalid repository format before touching gh" {
  run "${REPO_ROOT}/script/setup-team-protection.sh" not-a-valid-repo --dry-run
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid repository format"* ]]
}

@test "fails with installation guidance when gh CLI is missing" {
  # gh だけを取り除いた PATH を作る。/usr/bin:/bin だけにすると macOS では
  # bash 3.2 が使われ、lib/output.sh の bash 4.0+ チェックで先に落ちてしまい
  # gh 不在時の分岐まで到達できない。
  mkdir -p "${TEST_TEMP_DIR}/bin"
  ln -sf "$(command -v bash)" "${TEST_TEMP_DIR}/bin/bash"
  local minimal_path="${TEST_TEMP_DIR}/bin:/usr/bin:/bin"

  if PATH="$minimal_path" command -v gh >/dev/null 2>&1; then
    skip "gh is available in the minimal PATH"
  fi

  run env PATH="$minimal_path" "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run
  [ "$status" -ne 0 ]
  [[ "$output" == *"GitHub CLI (gh) is not installed"* ]]
}

@test "fails with login guidance when gh is not authenticated" {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "auth" ] && [ "$2" = "status" ]; then
  exit 1
fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/gh"

  run env PATH="${TEST_TEMP_DIR}/bin:${PATH}" "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run
  [ "$status" -ne 0 ]
  [[ "$output" == *"Not authenticated with GitHub"* ]]
}

@test "fails with a clear error when the user lacks admin access" {
  setup_fake_gh

  run env MOCK_GH_ADMIN=false "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run
  [ "$status" -ne 0 ]
  [[ "$output" == *"You don't have admin access to owner/repo"* ]]
}

@test "fails when a target branch does not exist and --create-branches is not set" {
  setup_fake_gh

  run env MOCK_GH_BRANCH_EXIT=1 "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches main --skip-status-checks
  [ "$status" -ne 0 ]
  [[ "$output" == *"Branch main does not exist. Use --create-branches to create it."* ]]
}

@test "rejects invalid --protection-level values" {
  setup_fake_gh

  run "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches main --protection-level turbo
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid protection level: turbo"* ]]
}

@test "rejects invalid --merge-method values" {
  setup_fake_gh

  run "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches main --skip-status-checks --merge-method bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid merge method: bogus"* ]]
}

@test "dry-run applies the default-branch preset (no mandatory reviewers) to main" {
  setup_fake_gh

  run "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches main --skip-status-checks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applying default branch defaults (enforce_admins=false, reviewers=0, code_owner_reviews=false)"* ]]
  # dry-run pretty-prints the API payload with jq when it is available, which
  # adds a space after ":" — match both the raw and pretty-printed forms.
  [[ "$output" =~ \"required_approving_review_count\"[[:space:]]*:[[:space:]]*0 ]]
}

@test "dry-run applies the environment-branch preset to production" {
  setup_fake_gh

  run "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches production --skip-status-checks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applying environment branch defaults (enforce_admins=false, reviewers=1, code_owner_reviews=true)"* ]]
  [[ "$output" =~ \"required_approving_review_count\"[[:space:]]*:[[:space:]]*1 ]]
  [[ "$output" =~ \"require_code_owner_reviews\"[[:space:]]*:[[:space:]]*true ]]
}

@test "dry-run --uniform bypasses branch-type defaults for main" {
  setup_fake_gh

  run "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches main --uniform --skip-status-checks
  [ "$status" -eq 0 ]
  [[ "$output" != *"Applying default branch defaults"* ]]
  # Falls back to the global --reviewers default (1) instead of the
  # main-branch preset (0) since branch-type defaults are disabled.
  [[ "$output" =~ \"required_approving_review_count\"[[:space:]]*:[[:space:]]*1 ]]
}

@test "dry-run --protection-level strict downgrades merge method and raises reviewers" {
  setup_fake_gh

  run "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches main --protection-level strict --skip-status-checks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Strict mode requires linear history. Switching merge method from 'merge' to 'squash'."* ]]
  [[ "$output" == *"Applying strict protection level (reviewers=2"* ]]
  [[ "$output" =~ \"required_approving_review_count\"[[:space:]]*:[[:space:]]*2 ]]
  [[ "$output" =~ \"enforce_admins\"[[:space:]]*:[[:space:]]*true ]]
  [[ "$output" =~ \"required_linear_history\"[[:space:]]*:[[:space:]]*true ]]
  [[ "$output" == *"Signed commits: true"* ]]
}

@test "dry-run --skip-status-checks disables required status check contexts" {
  setup_fake_gh

  run "${REPO_ROOT}/script/setup-team-protection.sh" owner/repo --dry-run --branches main --skip-status-checks
  [ "$status" -eq 0 ]
  [[ "$output" =~ \"strict\"[[:space:]]*:[[:space:]]*false ]]
  [[ "$output" =~ \"contexts\"[[:space:]]*:[[:space:]]*\[\] ]]
}
