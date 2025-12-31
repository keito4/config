#!/usr/bin/env bash
# Pre-PR Checklist - Comprehensive checks before creating a pull request

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Options
SKIP_TESTS=false
SKIP_INTEGRATION=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --skip-integration)
      SKIP_INTEGRATION=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --skip-tests         Skip all tests"
      echo "  --skip-integration   Skip integration tests only"
      echo "  --verbose            Verbose output"
      echo "  --help               Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}📋 Pre-PR Checklist${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}✗ Not in a git repository${NC}"
  exit 1
fi

# Quality Checks
echo -e "${BLUE}✅ Quality Checks${NC}"

# Lint
echo -n "  • Running lint check... "
if npm run lint > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗ Failed${NC}"
  echo -e "${YELLOW}  Run: npm run lint:fix${NC}"
  exit 1
fi

# Format
echo -n "  • Running format check... "
if npm run format:check > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗ Failed${NC}"
  echo -e "${YELLOW}  Run: npm run format${NC}"
  exit 1
fi

# Shellcheck
if command -v shellcheck > /dev/null 2>&1; then
  echo -n "  • Running shellcheck... "
  if npm run shellcheck > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗ Failed${NC}"
    exit 1
  fi
fi

# Tests
if [ "$SKIP_TESTS" = false ]; then
  echo -n "  • Running unit tests... "
  if npm test > /dev/null 2>&1; then
    TEST_OUTPUT=$(npm test 2>&1 | tail -5)
    PASSED=$(echo "$TEST_OUTPUT" | grep -oP '\d+(?= passed)' || echo "0")
    echo -e "${GREEN}✓ ($PASSED tests passed)${NC}"

    # Coverage
    if [ -f "coverage/coverage-summary.json" ]; then
      COVERAGE=$(node -pe "JSON.parse(require('fs').readFileSync('coverage/coverage-summary.json')).total.lines.pct")
      if (( $(echo "$COVERAGE >= 70" | bc -l) )); then
        echo -e "  • Coverage: ${GREEN}${COVERAGE}%${NC} (threshold: 70%)"
      else
        echo -e "  • Coverage: ${RED}${COVERAGE}%${NC} (threshold: 70%)"
        exit 1
      fi
    fi
  else
    echo -e "${RED}✗ Failed${NC}"
    exit 1
  fi

  # Integration tests
  if [ "$SKIP_INTEGRATION" = false ] && command -v bats > /dev/null 2>&1; then
    echo -n "  • Running integration tests... "
    if npm run test:integration > /dev/null 2>&1; then
      echo -e "${GREEN}✓${NC}"
    else
      echo -e "${YELLOW}⚠ Integration tests failed or not available${NC}"
    fi
  fi
fi

echo ""

# PR Analysis
echo -e "${BLUE}📊 PR Analysis${NC}"

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  echo -e "${RED}✗ Cannot create PR from main/master branch${NC}"
  exit 1
fi

# Calculate diff stats
MAIN_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
if ! git rev-parse "origin/$MAIN_BRANCH" > /dev/null 2>&1; then
  MAIN_BRANCH="main"
fi

ADDITIONS=$(git diff "origin/$MAIN_BRANCH"...HEAD --numstat | awk '{sum+=$1} END {print sum}')
DELETIONS=$(git diff "origin/$MAIN_BRANCH"...HEAD --numstat | awk '{sum+=$2} END {print sum}')
TOTAL_LINES=$((ADDITIONS + DELETIONS))
FILE_COUNT=$(git diff "origin/$MAIN_BRANCH"...HEAD --name-only | wc -l | tr -d ' ')

# Determine size label
if [ "$TOTAL_LINES" -lt 100 ] && [ "$FILE_COUNT" -lt 10 ]; then
  SIZE_LABEL="size/S"
  SIZE_NAME="Small"
elif [ "$TOTAL_LINES" -lt 300 ] && [ "$FILE_COUNT" -lt 20 ]; then
  SIZE_LABEL="size/M"
  SIZE_NAME="Medium"
elif [ "$TOTAL_LINES" -lt 1000 ] && [ "$FILE_COUNT" -lt 30 ]; then
  SIZE_LABEL="size/L"
  SIZE_NAME="Large"
else
  SIZE_LABEL="size/XL"
  SIZE_NAME="Extra Large"
fi

echo "  • Size: $SIZE_NAME (+$ADDITIONS -$DELETIONS lines, $FILE_COUNT files)"
echo "  • Suggested label: $SIZE_LABEL"

if [ "$SIZE_LABEL" = "size/XL" ]; then
  echo -e "${YELLOW}  ⚠ Consider breaking this PR into smaller chunks${NC}"
fi

# Check for linked issues
COMMIT_MESSAGES=$(git log "origin/$MAIN_BRANCH"..HEAD --pretty=format:"%s %b")
LINKED_ISSUES=$(echo "$COMMIT_MESSAGES" | grep -oP '#\d+' | sort -u || true)
if [ -n "$LINKED_ISSUES" ]; then
  echo "  • Linked issues: $(echo $LINKED_ISSUES | tr '\n' ' ')"
else
  echo -e "${YELLOW}  ⚠ No linked issues found${NC}"
fi

# Check commit messages
COMMIT_COUNT=$(git rev-list --count "origin/$MAIN_BRANCH"..HEAD)
INVALID_COMMITS=$(git log "origin/$MAIN_BRANCH"..HEAD --pretty=format:"%s" | grep -vE '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .+' || true)
if [ -z "$INVALID_COMMITS" ]; then
  echo "  • Commits: $COMMIT_COUNT (all follow conventional commits)"
else
  echo -e "${YELLOW}  ⚠ Some commits don't follow conventional commits format${NC}"
fi

echo ""

# Branch Status
echo -e "${BLUE}🔄 Branch Status${NC}"

# Check if up-to-date with main
git fetch origin "$MAIN_BRANCH" > /dev/null 2>&1
BEHIND_COUNT=$(git rev-list --count HEAD.."origin/$MAIN_BRANCH")
if [ "$BEHIND_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}✓${NC} Up-to-date with $MAIN_BRANCH"
else
  echo -e "${YELLOW}  ⚠ Behind $MAIN_BRANCH by $BEHIND_COUNT commits${NC}"
  echo -e "${YELLOW}  Consider: git rebase origin/$MAIN_BRANCH${NC}"
fi

# Check for merge conflicts
if git merge-tree "$(git merge-base HEAD "origin/$MAIN_BRANCH")" HEAD "origin/$MAIN_BRANCH" | grep -q '<<<<<<<'; then
  echo -e "${RED}  ✗ Potential merge conflicts detected${NC}"
  exit 1
else
  echo -e "  ${GREEN}✓${NC} No merge conflicts"
fi

echo ""
echo -e "${GREEN}✨ Ready to create PR!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review your changes: git diff origin/$MAIN_BRANCH...HEAD"
echo "  2. Create PR: gh pr create"
echo "  3. Add label: gh pr edit --add-label $SIZE_LABEL"
