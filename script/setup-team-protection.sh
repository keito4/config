#!/usr/bin/env bash
# Team Repository Protection Setup
#
# This script configures recommended GitHub settings for team development:
# - Branch protection rules (no direct push, required reviews, status checks)
# - Repository settings (squash merge only, auto-delete branches)
# - Security settings (Dependabot, code scanning, secret scanning)
#
# Usage:
#   bash script/setup-team-protection.sh [owner/repo] [options]
#
# Options:
#   --interactive          Interactive mode with confirmations
#   --dry-run             Show what would be done without making changes
#   --reviewers N         Number of required reviewers (default: 1)
#   --enforce-admins      Apply protection rules to administrators
#   --branches B1,B2      Comma-separated list of branches to protect (default: main)
#   --skip-status-checks  Skip required status checks configuration
#   --create-branches     Create branches if they don't exist
#   --merge-method METHOD Merge method: squash, merge, rebase, all, none (default: squash)
#   --protection-level LV Protection level: standard or strict (default: standard)
#                         strict: 2 reviewers, enforce admins, linear history,
#                         conversation resolution, signed commits, last push approval
#   --help                Show this help message

set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"

# Default configuration
REVIEWERS=1
ENFORCE_ADMINS=false
BRANCHES="main"
INTERACTIVE=false
DRY_RUN=false
SKIP_STATUS_CHECKS=false
CREATE_BRANCHES=false
MERGE_METHOD="merge"  # Options: squash, merge, rebase, all, none
PROTECTION_LEVEL="standard"  # Options: standard, strict

# Parse arguments
REPO=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --interactive)
      INTERACTIVE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --reviewers)
      REVIEWERS="$2"
      shift 2
      ;;
    --enforce-admins)
      ENFORCE_ADMINS=true
      shift
      ;;
    --branches)
      BRANCHES="$2"
      shift 2
      ;;
    --skip-status-checks)
      SKIP_STATUS_CHECKS=true
      shift
      ;;
    --create-branches)
      CREATE_BRANCHES=true
      shift
      ;;
    --merge-method)
      MERGE_METHOD="$2"
      shift 2
      ;;
    --protection-level)
      PROTECTION_LEVEL="$2"
      shift 2
      ;;
    --help)
      grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //; s/^#//'
      exit 0
      ;;
    *)
      if [[ -z "$REPO" ]]; then
        REPO="$1"
      else
        error "Unknown argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

# Get repository info
if [[ -z "$REPO" ]]; then
  # Try to get from git remote
  if git remote get-url origin &>/dev/null; then
    REPO_URL=$(git remote get-url origin)
    REPO=$(echo "$REPO_URL" | sed -E 's|.*github\.com[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
    info "Detected repository: $REPO"
  else
    error "Could not detect repository. Please provide owner/repo as argument."
    exit 1
  fi
fi

# Validate repository format
if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
  error "Invalid repository format. Expected: owner/repo, got: $REPO"
  exit 1
fi

# Check if gh is installed
if ! command -v gh &>/dev/null; then
  error "GitHub CLI (gh) is not installed. Please install it first:"
  echo "  brew install gh"
  echo "  or visit https://cli.github.com/"
  exit 1
fi

# Check if authenticated
if ! gh auth status &>/dev/null; then
  error "Not authenticated with GitHub. Please run:"
  echo "  gh auth login"
  exit 1
fi

# Check if user has admin access
PERMISSIONS=$(gh api "repos/$REPO" --jq '.permissions.admin // false' 2>/dev/null || echo "false")
if [[ "$PERMISSIONS" != "true" ]]; then
  error "You don't have admin access to $REPO"
  echo "Branch protection requires repository admin permissions."
  exit 1
fi

# Validate protection level
case "$PROTECTION_LEVEL" in
  standard|strict) ;;
  *)
    error "Invalid protection level: $PROTECTION_LEVEL. Valid options: standard, strict"
    exit 1
    ;;
esac

# Strict mode requires linear history, which is incompatible with merge commits
if [[ "$PROTECTION_LEVEL" == "strict" && "$MERGE_METHOD" == "merge" ]]; then
  warning "Strict mode requires linear history. Switching merge method from 'merge' to 'squash'."
  MERGE_METHOD="squash"
fi

info "Setting up team protection for $REPO"
echo ""

# Interactive confirmation
if [[ "$INTERACTIVE" == "true" ]]; then
  echo "Configuration:"
  echo "  Repository: $REPO"
  echo "  Branches: $BRANCHES"
  echo "  Required reviewers: $REVIEWERS"
  echo "  Enforce for admins: $ENFORCE_ADMINS"
  echo "  Skip status checks: $SKIP_STATUS_CHECKS"
  echo "  Merge method: $MERGE_METHOD"
  echo "  Protection level: $PROTECTION_LEVEL"
  echo ""
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Cancelled."
    exit 0
  fi
fi

# Function to execute or dry-run a command
execute() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] $*"
  else
    "$@"
  fi
}

# Function to setup branch protection
setup_branch_protection() {
  local branch=$1
  info "Setting up protection for branch: $branch"

  # Check if branch exists
  if ! gh api "repos/$REPO/branches/$branch" &>/dev/null; then
    if [[ "$CREATE_BRANCHES" == "true" ]]; then
      warning "Branch $branch does not exist. Creating..."
      execute gh api "repos/$REPO/git/refs" \
        --method POST \
        --field "ref=refs/heads/$branch" \
        --field "sha=$(gh api "repos/$REPO/git/refs/heads/main" --jq '.object.sha')" \
        2>/dev/null || true
    else
      error "Branch $branch does not exist. Use --create-branches to create it."
      return 1
    fi
  fi

  # Apply protection level presets
  local reviewers=$REVIEWERS
  local enforce_admins=$ENFORCE_ADMINS
  local require_linear_history=false
  local require_last_push_approval=false
  local require_conversation_resolution=false
  local require_signed_commits=false

  if [[ "$PROTECTION_LEVEL" == "strict" ]]; then
    # Strict: maximum protection for production-grade branches
    if [[ "$REVIEWERS" -lt 2 ]]; then
      reviewers=2
    fi
    enforce_admins=true
    require_linear_history=true
    require_last_push_approval=true
    require_conversation_resolution=true
    require_signed_commits=true
    info "Applying strict protection level (reviewers=$reviewers, enforce_admins, linear_history, signed_commits, last_push_approval)"
  fi

  # Build protection configuration
  local protection_config='{'
  protection_config+='"required_status_checks":{'

  if [[ "$SKIP_STATUS_CHECKS" == "false" ]]; then
    protection_config+='"strict":true,'
    # CI workflow の Quality Gate ジョブが全チェックを集約するため、
    # 単一の required check として使用する
    protection_config+='"contexts":["Quality Gate"]'
  else
    protection_config+='"strict":false,'
    protection_config+='"contexts":[]'
  fi
  protection_config+='},'

  protection_config+='"required_pull_request_reviews":{'
  protection_config+="\"required_approving_review_count\":$reviewers,"
  protection_config+='"dismiss_stale_reviews":true,'
  protection_config+='"require_code_owner_reviews":true,'
  protection_config+="\"require_last_push_approval\":$require_last_push_approval"
  protection_config+='},'

  if [[ "$enforce_admins" == "true" ]]; then
    protection_config+='"enforce_admins":true,'
  else
    protection_config+='"enforce_admins":false,'
  fi

  protection_config+='"restrictions":null,'
  protection_config+='"allow_force_pushes":false,'
  protection_config+='"allow_deletions":false,'
  protection_config+="\"required_linear_history\":$require_linear_history,"
  protection_config+="\"required_conversation_resolution\":$require_conversation_resolution"
  protection_config+='}'

  # Apply branch protection
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would apply branch protection to $branch:"
    echo "  Reviewers: $reviewers"
    echo "  Enforce admins: $enforce_admins"
    echo "  Linear history: $require_linear_history"
    echo "  Last push approval: $require_last_push_approval"
    echo "  Conversation resolution: $require_conversation_resolution"
    echo "  Signed commits: $require_signed_commits"
    echo ""
    echo "[DRY RUN] API payload:"
    echo "$protection_config" | jq '.' 2>/dev/null || echo "$protection_config"
  else
    if gh api "repos/$REPO/branches/$branch/protection" \
      --method PUT \
      --input - <<< "$protection_config" &>/dev/null; then
      success "Branch protection applied to $branch"
    else
      error "Failed to apply branch protection to $branch"
      return 1
    fi

    # Manage signed commits requirement (separate API endpoint)
    if [[ "$require_signed_commits" == "true" ]]; then
      if gh api "repos/$REPO/branches/$branch/protection/required_signatures" \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        &>/dev/null; then
        success "Signed commits required for $branch"
      else
        warning "Could not enable signed commits requirement for $branch"
      fi
    else
      # Disable signed commits to ensure idempotent standard mode
      gh api "repos/$REPO/branches/$branch/protection/required_signatures" \
        --method DELETE \
        -H "Accept: application/vnd.github+json" \
        &>/dev/null 2>&1 || true
    fi
  fi
}

# Function to configure repository settings
setup_repository_settings() {
  info "Configuring repository settings..."

  # Determine merge method settings based on MERGE_METHOD
  local allow_squash=false
  local allow_merge=false
  local allow_rebase=false

  case "$MERGE_METHOD" in
    squash)
      allow_squash=true
      allow_merge=false
      allow_rebase=false
      ;;
    merge)
      allow_squash=false
      allow_merge=true
      allow_rebase=false
      ;;
    rebase)
      allow_squash=false
      allow_merge=false
      allow_rebase=true
      ;;
    all)
      allow_squash=true
      allow_merge=true
      allow_rebase=true
      ;;
    none)
      allow_squash=false
      allow_merge=false
      allow_rebase=false
      ;;
    *)
      error "Invalid merge method: $MERGE_METHOD. Valid options: squash, merge, rebase, all, none"
      return 1
      ;;
  esac

  info "Merge method: $MERGE_METHOD (squash=$allow_squash, merge=$allow_merge, rebase=$allow_rebase)"

  # Build API command
  local api_cmd="gh api repos/$REPO --method PATCH"
  api_cmd+=" --field allow_squash_merge=$allow_squash"
  api_cmd+=" --field allow_merge_commit=$allow_merge"
  api_cmd+=" --field allow_rebase_merge=$allow_rebase"
  api_cmd+=" --field delete_branch_on_merge=true"
  api_cmd+=" --field allow_auto_merge=false"

  if execute eval "$api_cmd" &>/dev/null; then
    success "Repository settings updated (merge method: $MERGE_METHOD)"
  else
    error "Failed to update repository settings"
    return 1
  fi
}

# Function to enable security features
setup_security_features() {
  info "Enabling security features..."

  # Enable vulnerability alerts
  if execute gh api "repos/$REPO/vulnerability-alerts" \
    --method PUT \
    &>/dev/null; then
    success "Vulnerability alerts enabled"
  else
    warning "Could not enable vulnerability alerts"
  fi

  # Enable automated security fixes (Dependabot)
  if execute gh api "repos/$REPO/automated-security-fixes" \
    --method PUT \
    &>/dev/null; then
    success "Automated security fixes enabled"
  else
    warning "Could not enable automated security fixes"
  fi

  # Enable private vulnerability reporting
  if execute gh api "repos/$REPO/private-vulnerability-reporting" \
    --method PUT \
    &>/dev/null; then
    success "Private vulnerability reporting enabled"
  else
    warning "Could not enable private vulnerability reporting"
  fi

  # Enable secret scanning and push protection
  # Note: These require GitHub Advanced Security for private repos
  local security_config='{"security_and_analysis":{'
  security_config+='"secret_scanning":{"status":"enabled"},'
  security_config+='"secret_scanning_push_protection":{"status":"enabled"}'
  security_config+='}}'

  if execute gh api "repos/$REPO" \
    --method PATCH \
    --input - <<< "$security_config" &>/dev/null; then
    success "Secret scanning and push protection enabled"
  else
    warning "Could not enable secret scanning (may require GitHub Advanced Security)"
  fi
}

# Main execution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Team Repository Protection Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Setup branch protection for each branch
IFS=',' read -ra BRANCH_ARRAY <<< "$BRANCHES"
for branch in "${BRANCH_ARRAY[@]}"; do
  setup_branch_protection "$branch" || exit 1
done

echo ""

# Setup repository settings
setup_repository_settings

echo ""

# Setup security features
setup_security_features

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Team protection setup completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Next steps:"
echo "  1. Verify branch protection: gh api repos/$REPO/branches/main/protection | jq"
echo "  2. Test by trying to push directly: git push origin main (should fail)"
echo "  3. Create a PR and verify review requirements work"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  warning "This was a dry run. No actual changes were made."
  echo "Run without --dry-run to apply changes."
fi
