#!/usr/bin/env bash
# Branch Cleanup - Remove merged and stale branches

set -euo pipefail

# Source shared output library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/output.sh" 2>/dev/null || {
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
}

# Options
DRY_RUN=false
INCLUDE_REMOTE=false
AUTO_CONFIRM=false
STALE_DAYS=30
MERGED_ONLY=false

# Protected branches
PROTECTED_BRANCHES=("main" "master" "develop" "staging" "production")

# Populated by detect_branches / find_merged_branches / find_stale_branches
CURRENT_BRANCH=""
MAIN_BRANCH=""
MERGED_BRANCHES=()
STALE_BRANCHES=()

# Return success (0) when $1 is a protected branch or the current branch.
# Relies on the global PROTECTED_BRANCHES array and CURRENT_BRANCH variable.
is_protected_branch() {
  local branch=$1
  local protected

  if [ "$branch" = "$CURRENT_BRANCH" ]; then
    return 0
  fi

  for protected in "${PROTECTED_BRANCHES[@]}"; do
    if [ "$branch" = "$protected" ]; then
      return 0
    fi
  done

  return 1
}

# Print up to the first 5 entries of a branch list as "  <icon> <branch>
# (<date_prefix><last_commit>)", then a "... and N more" summary line when
# the list is longer than that.
print_branch_group() {
  local icon=$1
  local date_prefix=$2
  shift 2
  local branches=("$@")
  local branch last_commit

  for branch in "${branches[@]:0:5}"; do
    last_commit=$(git log -1 --format="%cr" "$branch" 2>/dev/null || echo "unknown")
    echo "  $icon $branch (${date_prefix}${last_commit})"
  done
  if [ "${#branches[@]}" -gt 5 ]; then
    echo "  ... and $((${#branches[@]} - 5)) more"
  fi
}

print_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --dry-run        Preview without deleting"
  echo "  --remote         Include remote branches"
  echo "  --yes, -y        Auto-confirm deletion"
  echo "  --stale-days N   Staleness threshold (default: 30)"
  echo "  --merged-only    Only delete merged branches"
  echo "  --help           Show this help message"
}

# Parse CLI options into the global DRY_RUN/INCLUDE_REMOTE/AUTO_CONFIRM/STALE_DAYS/MERGED_ONLY vars
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --remote)
        INCLUDE_REMOTE=true
        shift
        ;;
      --yes|-y)
        AUTO_CONFIRM=true
        shift
        ;;
      --stale-days)
        STALE_DAYS="$2"
        shift 2
        ;;
      --merged-only)
        MERGED_ONLY=true
        shift
        ;;
      --help)
        print_usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
  done
}

# Abort with an error message unless the current directory is inside a git repository
ensure_git_repository() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗ Not in a git repository${NC}"
    exit 1
  fi
}

# Populate the global CURRENT_BRANCH and MAIN_BRANCH variables
detect_branches() {
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo -e "📍 Current branch: ${GREEN}$CURRENT_BRANCH${NC}"

  MAIN_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5 2>/dev/null || echo "main")
  if ! git rev-parse --verify "$MAIN_BRANCH" > /dev/null 2>&1; then
    MAIN_BRANCH="master"
  fi
}

# Populate the global MERGED_BRANCHES array with non-protected branches already merged into MAIN_BRANCH
find_merged_branches() {
  MERGED_BRANCHES=()
  while IFS= read -r branch; do
    if ! is_protected_branch "$branch"; then
      MERGED_BRANCHES+=("$branch")
    fi
  done < <(git branch --merged "$MAIN_BRANCH" | sed 's/^[* ]*//' | grep -v "^$MAIN_BRANCH$" || true)
}

# Populate the global STALE_BRANCHES array with non-protected, not-yet-merged branches whose
# last commit predates STALE_DAYS. No-op when MERGED_ONLY is set.
find_stale_branches() {
  STALE_BRANCHES=()
  if [ "$MERGED_ONLY" = true ]; then
    return
  fi

  local cutoff_date
  local branch
  local last_commit_date
  cutoff_date=$(date -v-"${STALE_DAYS}"d +%s 2>/dev/null || date -d "${STALE_DAYS} days ago" +%s 2>/dev/null || echo "0")

  while IFS= read -r branch; do
    # Skip if already in merged list
    if [[ " ${MERGED_BRANCHES[*]} " =~ \ ${branch}\  ]]; then
      continue
    fi

    if ! is_protected_branch "$branch"; then
      last_commit_date=$(git log -1 --format=%ct "$branch" 2>/dev/null || echo "0")

      if [ "$last_commit_date" -lt "$cutoff_date" ] && [ "$last_commit_date" != "0" ]; then
        STALE_BRANCHES+=("$branch")
      fi
    fi
  done < <(git branch | sed 's/^[* ]*//' | grep -v "^$MAIN_BRANCH$" || true)
}

# Print the branch count summary (total/merged/stale)
show_analysis() {
  echo -e "${BLUE}📊 Analysis${NC}"
  local total_branches
  total_branches=$(git branch | wc -l | tr -d ' ')
  echo "  • Total local branches: $total_branches"
  echo "  • Merged branches: ${#MERGED_BRANCHES[@]}"
  if [ "$MERGED_ONLY" = false ]; then
    echo "  • Stale branches (${STALE_DAYS}+ days): ${#STALE_BRANCHES[@]}"
  fi
  echo ""
}

# Print the merged/stale branch groups that are about to be deleted
show_branches_to_delete() {
  local total_to_delete=$1

  echo -e "${YELLOW}🗑️  Branches to delete ($total_to_delete):${NC}"
  echo ""

  if [ "${#MERGED_BRANCHES[@]}" -gt 0 ]; then
    echo -e "${GREEN}Merged (${#MERGED_BRANCHES[@]}):${NC}"
    print_branch_group "✓" "merged " "${MERGED_BRANCHES[@]}"
    echo ""
  fi

  if [ "${#STALE_BRANCHES[@]}" -gt 0 ]; then
    echo -e "${YELLOW}Stale (${#STALE_BRANCHES[@]}):${NC}"
    print_branch_group "⚠" "" "${STALE_BRANCHES[@]}"
    echo ""
  fi
}

# Prompt the user unless AUTO_CONFIRM is set. Returns failure (1) when the user declines.
confirm_deletion() {
  if [ "$AUTO_CONFIRM" = true ]; then
    return 0
  fi

  echo -n "Delete these branches? [y/N]: "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    return 1
  fi
}

# Delete every branch in MERGED_BRANCHES/STALE_BRANCHES, printing progress per branch
delete_branches() {
  echo ""
  echo "Deleting branches..."
  local deleted_count=0
  local branch

  for branch in "${MERGED_BRANCHES[@]}" "${STALE_BRANCHES[@]}"; do
    if git branch -D "$branch" > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} Deleted $branch"
      deleted_count=$((deleted_count + 1))
    else
      echo -e "  ${RED}✗${NC} Failed to delete $branch"
    fi
  done

  echo ""
  echo -e "${GREEN}✨ Cleanup complete! Removed $deleted_count branches.${NC}"
}

# Remote branch cleanup (best-effort; currently a placeholder pointing at manual cleanup)
cleanup_remote_branches() {
  if [ "$INCLUDE_REMOTE" != true ]; then
    return
  fi

  echo ""
  echo -e "${BLUE}🌐 Remote Branch Cleanup${NC}"
  echo "  (This requires GitHub CLI and proper permissions)"
  echo ""

  if command -v gh > /dev/null 2>&1; then
    # This is a placeholder - actual implementation would require more logic
    echo "  Remote cleanup not yet implemented"
    echo "  Use: git push origin --delete <branch-name>"
  else
    echo "  GitHub CLI (gh) not installed"
  fi
}

main() {
  parse_args "$@"

  echo -e "${BLUE}🧹 Branch Cleanup${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  ensure_git_repository
  detect_branches

  echo -e "🔒 Protected: ${PROTECTED_BRANCHES[*]}"
  echo ""

  git fetch --prune > /dev/null 2>&1

  find_merged_branches
  find_stale_branches

  show_analysis

  local total_to_delete=$((${#MERGED_BRANCHES[@]} + ${#STALE_BRANCHES[@]}))

  if [ "$total_to_delete" -eq 0 ]; then
    echo -e "${GREEN}✨ No branches to clean up!${NC}"
    exit 0
  fi

  show_branches_to_delete "$total_to_delete"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}ℹ️  Dry run mode - no branches deleted${NC}"
    echo "  Run without --dry-run to delete these branches"
    exit 0
  fi

  if ! confirm_deletion; then
    exit 0
  fi

  delete_branches
  cleanup_remote_branches
}

main "$@"
