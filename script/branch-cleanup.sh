#!/usr/bin/env bash
# Branch Cleanup - Remove merged and stale branches

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Options
DRY_RUN=false
INCLUDE_REMOTE=false
AUTO_CONFIRM=false
STALE_DAYS=30
MERGED_ONLY=false

# Protected branches
PROTECTED_BRANCHES=("main" "master" "develop" "staging" "production")

# Parse arguments
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
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --dry-run        Preview without deleting"
      echo "  --remote         Include remote branches"
      echo "  --yes, -y        Auto-confirm deletion"
      echo "  --stale-days N   Staleness threshold (default: 30)"
      echo "  --merged-only    Only delete merged branches"
      echo "  --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}🧹 Branch Cleanup${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}✗ Not in a git repository${NC}"
  exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "📍 Current branch: ${GREEN}$CURRENT_BRANCH${NC}"

# Get main branch
MAIN_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5 2>/dev/null || echo "main")
if ! git rev-parse --verify "$MAIN_BRANCH" > /dev/null 2>&1; then
  MAIN_BRANCH="master"
fi

echo -e "🔒 Protected: ${PROTECTED_BRANCHES[*]}"
echo ""

# Fetch latest
git fetch --prune > /dev/null 2>&1

# Find merged branches
MERGED_BRANCHES=()
while IFS= read -r branch; do
  # Skip protected branches
  is_protected=false
  for protected in "${PROTECTED_BRANCHES[@]}"; do
    if [ "$branch" = "$protected" ]; then
      is_protected=true
      break
    fi
  done

  # Skip current branch
  if [ "$branch" = "$CURRENT_BRANCH" ]; then
    is_protected=true
  fi

  if [ "$is_protected" = false ]; then
    MERGED_BRANCHES+=("$branch")
  fi
done < <(git branch --merged "$MAIN_BRANCH" | sed 's/^[* ]*//' | grep -v "^$MAIN_BRANCH$" || true)

# Find stale branches (if not merged-only)
STALE_BRANCHES=()
if [ "$MERGED_ONLY" = false ]; then
  CUTOFF_DATE=$(date -v-"${STALE_DAYS}"d +%s 2>/dev/null || date -d "${STALE_DAYS} days ago" +%s 2>/dev/null || echo "0")

  while IFS= read -r branch; do
    # Skip if already in merged list
    if [[ " ${MERGED_BRANCHES[*]} " =~ \ ${branch}\  ]]; then
      continue
    fi

    # Skip protected branches and current
    is_protected=false
    for protected in "${PROTECTED_BRANCHES[@]}"; do
      if [ "$branch" = "$protected" ]; then
        is_protected=true
        break
      fi
    done

    if [ "$branch" = "$CURRENT_BRANCH" ]; then
      is_protected=true
    fi

    if [ "$is_protected" = false ]; then
      # Get last commit date
      LAST_COMMIT_DATE=$(git log -1 --format=%ct "$branch" 2>/dev/null || echo "0")

      if [ "$LAST_COMMIT_DATE" -lt "$CUTOFF_DATE" ] && [ "$LAST_COMMIT_DATE" != "0" ]; then
        STALE_BRANCHES+=("$branch")
      fi
    fi
  done < <(git branch | sed 's/^[* ]*//' | grep -v "^$MAIN_BRANCH$" || true)
fi

# Display analysis
echo -e "${BLUE}📊 Analysis${NC}"
TOTAL_BRANCHES=$(git branch | wc -l | tr -d ' ')
echo "  • Total local branches: $TOTAL_BRANCHES"
echo "  • Merged branches: ${#MERGED_BRANCHES[@]}"
if [ "$MERGED_ONLY" = false ]; then
  echo "  • Stale branches (${STALE_DAYS}+ days): ${#STALE_BRANCHES[@]}"
fi
echo ""

# Calculate total to delete
TOTAL_TO_DELETE=$((${#MERGED_BRANCHES[@]} + ${#STALE_BRANCHES[@]}))

if [ "$TOTAL_TO_DELETE" -eq 0 ]; then
  echo -e "${GREEN}✨ No branches to clean up!${NC}"
  exit 0
fi

echo -e "${YELLOW}🗑️  Branches to delete ($TOTAL_TO_DELETE):${NC}"
echo ""

# Show merged branches
if [ "${#MERGED_BRANCHES[@]}" -gt 0 ]; then
  echo -e "${GREEN}Merged (${#MERGED_BRANCHES[@]}):${NC}"
  for branch in "${MERGED_BRANCHES[@]:0:5}"; do
    LAST_COMMIT=$(git log -1 --format="%cr" "$branch" 2>/dev/null || echo "unknown")
    echo "  ✓ $branch (merged $LAST_COMMIT)"
  done
  if [ "${#MERGED_BRANCHES[@]}" -gt 5 ]; then
    echo "  ... and $((${#MERGED_BRANCHES[@]} - 5)) more"
  fi
  echo ""
fi

# Show stale branches
if [ "${#STALE_BRANCHES[@]}" -gt 0 ]; then
  echo -e "${YELLOW}Stale (${#STALE_BRANCHES[@]}):${NC}"
  for branch in "${STALE_BRANCHES[@]:0:5}"; do
    LAST_COMMIT=$(git log -1 --format="%cr" "$branch" 2>/dev/null || echo "unknown")
    echo "  ⚠ $branch ($LAST_COMMIT)"
  done
  if [ "${#STALE_BRANCHES[@]}" -gt 5 ]; then
    echo "  ... and $((${#STALE_BRANCHES[@]} - 5)) more"
  fi
  echo ""
fi

# Dry run mode
if [ "$DRY_RUN" = true ]; then
  echo -e "${BLUE}ℹ️  Dry run mode - no branches deleted${NC}"
  echo "  Run without --dry-run to delete these branches"
  exit 0
fi

# Confirm deletion
if [ "$AUTO_CONFIRM" = false ]; then
  echo -n "Delete these branches? [y/N]: "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

# Delete branches
echo ""
echo "Deleting branches..."
DELETED_COUNT=0

for branch in "${MERGED_BRANCHES[@]}" "${STALE_BRANCHES[@]}"; do
  if git branch -D "$branch" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Deleted $branch"
    ((DELETED_COUNT++))
  else
    echo -e "  ${RED}✗${NC} Failed to delete $branch"
  fi
done

echo ""
echo -e "${GREEN}✨ Cleanup complete! Removed $DELETED_COUNT branches.${NC}"

# Remote cleanup (if requested)
if [ "$INCLUDE_REMOTE" = true ]; then
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
fi
