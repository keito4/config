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
OWNER=$(echo "$REPO" | cut -d/ -f1)
REPO_NAME=$(echo "$REPO" | cut -d/ -f2)
PERMISSIONS=$(gh api "repos/$REPO" --jq '.permissions.admin // false' 2>/dev/null || echo "false")
if [[ "$PERMISSIONS" != "true" ]]; then
  error "You don't have admin access to $REPO"
  echo "Branch protection requires repository admin permissions."
  exit 1
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

  # Build protection configuration
  local protection_config='{'
  protection_config+='"required_status_checks":{'

  if [[ "$SKIP_STATUS_CHECKS" == "false" ]]; then
    protection_config+='"strict":true,'
    protection_config+='"contexts":["CI"]'
  else
    protection_config+='"strict":false,'
    protection_config+='"contexts":[]'
  fi
  protection_config+='},'

  protection_config+='"required_pull_request_reviews":{'
  protection_config+="\"required_approving_review_count\":$REVIEWERS,"
  protection_config+='"dismiss_stale_reviews":true,'
  protection_config+='"require_code_owner_reviews":false'
  protection_config+='},'

  if [[ "$ENFORCE_ADMINS" == "true" ]]; then
    protection_config+='"enforce_admins":true,'
  else
    protection_config+='"enforce_admins":false,'
  fi

  protection_config+='"restrictions":null,'
  protection_config+='"allow_force_pushes":{"enabled":false},'
  protection_config+='"allow_deletions":{"enabled":false},'
  protection_config+='"required_linear_history":{"enabled":false}'
  protection_config+='}'

  # Apply branch protection
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would apply branch protection to $branch with config:"
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
  fi
}

# Function to configure repository settings
setup_repository_settings() {
  info "Configuring repository settings..."

  # Enable squash merge only
  execute gh api "repos/$REPO" \
    --method PATCH \
    --field allow_squash_merge=true \
    --field allow_merge_commit=false \
    --field allow_rebase_merge=false \
    --field delete_branch_on_merge=true \
    &>/dev/null && success "Repository settings updated" || error "Failed to update repository settings"
}

# Function to enable security features
setup_security_features() {
  info "Enabling security features..."

  # Enable vulnerability alerts
  execute gh api "repos/$REPO/vulnerability-alerts" \
    --method PUT \
    &>/dev/null && success "Vulnerability alerts enabled" || warning "Could not enable vulnerability alerts"

  # Enable automated security fixes (Dependabot)
  execute gh api "repos/$REPO/automated-security-fixes" \
    --method PUT \
    &>/dev/null && success "Automated security fixes enabled" || warning "Could not enable automated security fixes"

  # Note: Code scanning and secret scanning require GitHub Advanced Security
  # and cannot be enabled via API for private repos on free tier
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
