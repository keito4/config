#!/usr/bin/env bash
# Changelog Generator - Generate CHANGELOG from conventional commits

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Options
SINCE_TAG=""
OUTPUT_FILE="CHANGELOG.md"
INCLUDE_ALL=false
DRY_RUN=false
SHOW_CONTRIBUTORS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --since)
      SINCE_TAG="$2"
      shift 2
      ;;
    --all)
      INCLUDE_ALL=true
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --include-all)
      INCLUDE_ALL=true
      shift
      ;;
    --contributors)
      SHOW_CONTRIBUTORS=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --since TAG          Generate changelog since this tag"
      echo "  --all                Include all commit types"
      echo "  --output FILE        Output file (default: CHANGELOG.md)"
      echo "  --include-all        Include all commit types"
      echo "  --contributors       Add contributors section"
      echo "  --dry-run            Preview without writing"
      echo "  --help               Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}📝 Changelog Generator${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}✗ Not in a git repository${NC}"
  exit 1
fi

# Get repository info
REPO_URL=$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's/git@github.com:/https:\/\/github.com\//')

# Determine range
if [ -z "$SINCE_TAG" ]; then
  LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [ -n "$LATEST_TAG" ]; then
    SINCE_TAG="$LATEST_TAG"
    echo "📌 Latest tag: $LATEST_TAG"
  else
    echo "📌 No tags found, generating from all commits"
    SINCE_TAG=""
  fi
else
  echo "📌 Generating since: $SINCE_TAG"
fi
echo ""

# Generate changelog content
CHANGELOG_CONTENT="# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Conventional Commits](https://conventionalcommits.org/).

"

# Get commits
if [ -n "$SINCE_TAG" ]; then
  COMMITS=$(git log "$SINCE_TAG"..HEAD --pretty=format:"%H|%s|%b" 2>/dev/null || git log --pretty=format:"%H|%s|%b")
else
  COMMITS=$(git log --pretty=format:"%H|%s|%b")
fi

# Group commits by type
declare -A FEATURES
declare -A FIXES
declare -A PERF
declare -A DOCS
declare -A BREAKING
declare -A OTHER

while IFS='|' read -r hash subject body; do
  # Extract type from conventional commit
  if [[ "$subject" =~ ^([a-z]+)(\([^)]+\))?:\ (.+)$ ]]; then
    TYPE="${BASH_REMATCH[1]}"
    MESSAGE="${BASH_REMATCH[3]}"

    # Check for breaking changes
    if echo "$body" | grep -q "BREAKING CHANGE"; then
      BREAKING["$hash"]="$MESSAGE"
    fi

    # Categorize
    case "$TYPE" in
      feat)
        FEATURES["$hash"]="$MESSAGE"
        ;;
      fix)
        FIXES["$hash"]="$MESSAGE"
        ;;
      perf)
        PERF["$hash"]="$MESSAGE"
        ;;
      docs)
        DOCS["$hash"]="$MESSAGE"
        ;;
      *)
        if [ "$INCLUDE_ALL" = true ]; then
          OTHER["$hash"]="$MESSAGE ($TYPE)"
        fi
        ;;
    esac
  fi
done <<< "$COMMITS"

# Add unreleased section
CHANGELOG_CONTENT+="## [Unreleased]

"

# Breaking changes first
if [ ${#BREAKING[@]} -gt 0 ]; then
  CHANGELOG_CONTENT+="### BREAKING CHANGES

"
  for hash in "${!BREAKING[@]}"; do
    SHORT_HASH=$(echo "$hash" | cut -c1-7)
    CHANGELOG_CONTENT+="- ${BREAKING[$hash]} ([$SHORT_HASH]($REPO_URL/commit/$hash))
"
  done
  CHANGELOG_CONTENT+="
"
fi

# Features
if [ ${#FEATURES[@]} -gt 0 ]; then
  CHANGELOG_CONTENT+="### Features

"
  for hash in "${!FEATURES[@]}"; do
    SHORT_HASH=$(echo "$hash" | cut -c1-7)
    MESSAGE="${FEATURES[$hash]}"

    # Check for PR reference
    if [[ "$MESSAGE" =~ \(#([0-9]+)\) ]]; then
      PR_NUM="${BASH_REMATCH[1]}"
      MESSAGE=$(echo "$MESSAGE" | sed "s/(#$PR_NUM)/([#$PR_NUM]($REPO_URL\/pull\/$PR_NUM))/")
    fi

    CHANGELOG_CONTENT+="- $MESSAGE ([$SHORT_HASH]($REPO_URL/commit/$hash))
"
  done
  CHANGELOG_CONTENT+="
"
fi

# Bug fixes
if [ ${#FIXES[@]} -gt 0 ]; then
  CHANGELOG_CONTENT+="### Bug Fixes

"
  for hash in "${!FIXES[@]}"; do
    SHORT_HASH=$(echo "$hash" | cut -c1-7)
    MESSAGE="${FIXES[$hash]}"

    if [[ "$MESSAGE" =~ \(#([0-9]+)\) ]]; then
      PR_NUM="${BASH_REMATCH[1]}"
      MESSAGE=$(echo "$MESSAGE" | sed "s/(#$PR_NUM)/([#$PR_NUM]($REPO_URL\/pull\/$PR_NUM))/")
    fi

    CHANGELOG_CONTENT+="- $MESSAGE ([$SHORT_HASH]($REPO_URL/commit/$hash))
"
  done
  CHANGELOG_CONTENT+="
"
fi

# Performance
if [ ${#PERF[@]} -gt 0 ]; then
  CHANGELOG_CONTENT+="### Performance Improvements

"
  for hash in "${!PERF[@]}"; do
    SHORT_HASH=$(echo "$hash" | cut -c1-7)
    CHANGELOG_CONTENT+="- ${PERF[$hash]} ([$SHORT_HASH]($REPO_URL/commit/$hash))
"
  done
  CHANGELOG_CONTENT+="
"
fi

# Documentation
if [ ${#DOCS[@]} -gt 0 ]; then
  CHANGELOG_CONTENT+="### Documentation

"
  for hash in "${!DOCS[@]}"; do
    SHORT_HASH=$(echo "$hash" | cut -c1-7)
    CHANGELOG_CONTENT+="- ${DOCS[$hash]} ([$SHORT_HASH]($REPO_URL/commit/$hash))
"
  done
  CHANGELOG_CONTENT+="
"
fi

# Other (if include-all)
if [ ${#OTHER[@]} -gt 0 ]; then
  CHANGELOG_CONTENT+="### Other Changes

"
  for hash in "${!OTHER[@]}"; do
    SHORT_HASH=$(echo "$hash" | cut -c1-7)
    CHANGELOG_CONTENT+="- ${OTHER[$hash]} ([$SHORT_HASH]($REPO_URL/commit/$hash))
"
  done
  CHANGELOG_CONTENT+="
"
fi

# Contributors
if [ "$SHOW_CONTRIBUTORS" = true ]; then
  CHANGELOG_CONTENT+="### Contributors

"
  if [ -n "$SINCE_TAG" ]; then
    CONTRIBUTORS=$(git log "$SINCE_TAG"..HEAD --format='%an' | sort -u)
  else
    CONTRIBUTORS=$(git log --format='%an' | sort -u)
  fi

  while IFS= read -r contributor; do
    CHANGELOG_CONTENT+="- $contributor
"
  done <<< "$CONTRIBUTORS"
  CHANGELOG_CONTENT+="
"
fi

# Output
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}Preview (dry run):${NC}"
  echo ""
  echo "$CHANGELOG_CONTENT"
else
  # Write to file
  echo "$CHANGELOG_CONTENT" > "$OUTPUT_FILE"
  echo -e "${GREEN}✓${NC} Changelog written to $OUTPUT_FILE"

  # Show stats
  TOTAL_ENTRIES=$((${#FEATURES[@]} + ${#FIXES[@]} + ${#PERF[@]} + ${#DOCS[@]} + ${#OTHER[@]}))
  echo ""
  echo "📊 Statistics:"
  echo "  • Features: ${#FEATURES[@]}"
  echo "  • Bug Fixes: ${#FIXES[@]}"
  echo "  • Performance: ${#PERF[@]}"
  echo "  • Documentation: ${#DOCS[@]}"
  if [ "$INCLUDE_ALL" = true ]; then
    echo "  • Other: ${#OTHER[@]}"
  fi
  echo "  • Breaking Changes: ${#BREAKING[@]}"
  echo "  • Total Entries: $TOTAL_ENTRIES"
fi
