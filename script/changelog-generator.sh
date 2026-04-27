#!/usr/bin/env bash
# Changelog Generator - Generate CHANGELOG from conventional commits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/output.sh" 2>/dev/null || {
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
}

SINCE_TAG=""
OUTPUT_FILE="CHANGELOG.md"
INCLUDE_ALL=false
DRY_RUN=false
SHOW_CONTRIBUTORS=false

show_help() {
  cat <<USAGE
Usage: $0 [OPTIONS]

Options:
  --since TAG          Generate changelog since this tag
  --all                Include all commit types
  --output FILE        Output file (default: CHANGELOG.md)
  --include-all        Include all commit types
  --contributors       Add contributors section
  --dry-run            Preview without writing
  --help               Show this help message
USAGE
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --since)        SINCE_TAG="$2"; shift 2 ;;
    --all|--include-all) INCLUDE_ALL=true; shift ;;
    --output)       OUTPUT_FILE="$2"; shift 2 ;;
    --contributors) SHOW_CONTRIBUTORS=true; shift ;;
    --dry-run)      DRY_RUN=true; shift ;;
    --help)         show_help; exit 0 ;;
    *)              echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo -e "${BLUE}📝 Changelog Generator${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}✗ Not in a git repository${NC}"
  exit 1
fi

REPO_URL=$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's/git@github.com:/https:\/\/github.com\//')

resolve_since_tag() {
  local latest
  if [ -n "$SINCE_TAG" ]; then
    echo "📌 Generating since: $SINCE_TAG"
    return
  fi
  latest=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [ -n "$latest" ]; then
    SINCE_TAG="$latest"
    echo "📌 Latest tag: $latest"
  else
    echo "📌 No tags found, generating from all commits"
  fi
}
resolve_since_tag
echo ""

declare -A FEATURES FIXES PERF DOCS BREAKING OTHER

categorize_commit() {
  local hash=$1 subject=$2 body=$3
  local regex='^([a-z]+)(\([^)]+\))?: (.+)$'
  [[ "$subject" =~ $regex ]] || return 0
  local type="${BASH_REMATCH[1]}"
  local message="${BASH_REMATCH[3]}"

  echo "$body" | grep -q "BREAKING CHANGE" && BREAKING["$hash"]="$message"

  case "$type" in
    feat)  FEATURES["$hash"]="$message" ;;
    fix)   FIXES["$hash"]="$message" ;;
    perf)  PERF["$hash"]="$message" ;;
    docs)  DOCS["$hash"]="$message" ;;
    *)     [[ "$INCLUDE_ALL" == "true" ]] && OTHER["$hash"]="$message ($type)" ;;
  esac
}

if [ -n "$SINCE_TAG" ]; then
  COMMITS=$(git log "$SINCE_TAG"..HEAD --pretty=format:"%H|%s|%b" 2>/dev/null || git log --pretty=format:"%H|%s|%b")
else
  COMMITS=$(git log --pretty=format:"%H|%s|%b")
fi

while IFS='|' read -r hash subject body; do
  categorize_commit "$hash" "$subject" "$body"
done <<< "$COMMITS"

format_message() {
  local msg=$1
  if [[ "$msg" =~ \(#([0-9]+)\) ]]; then
    local pr="${BASH_REMATCH[1]}"
    msg="${msg//(#$pr)/([#$pr]($REPO_URL/pull/$pr))}"
  fi
  echo "$msg"
}

# Render a section: title and array name (indirect access avoids nameref + set -u quirk).
render_section() {
  local title=$1 name=$2
  local size_var="${name}[@]"
  local -a keys=()
  eval "keys=(\"\${!${name}[@]}\")"
  [[ ${#keys[@]} -eq 0 ]] && return 0
  printf '### %s\n\n' "$title"
  local hash short msg val_var
  for hash in "${keys[@]}"; do
    short=${hash:0:7}
    val_var="${name}[$hash]"
    msg=$(format_message "${!val_var}")
    printf -- '- %s ([%s](%s/commit/%s))\n' "$msg" "$short" "$REPO_URL" "$hash"
  done
  printf '\n'
  : "${size_var}"  # silence shellcheck "unused"
}

build_changelog() {
  cat <<HEADER
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Conventional Commits](https://conventionalcommits.org/).

## [Unreleased]

HEADER
  render_section "BREAKING CHANGES"          BREAKING
  render_section "Features"                  FEATURES
  render_section "Bug Fixes"                 FIXES
  render_section "Performance Improvements"  PERF
  render_section "Documentation"             DOCS
  render_section "Other Changes"             OTHER

  [[ "$SHOW_CONTRIBUTORS" != "true" ]] && return 0

  printf '### Contributors\n\n'
  local contributors
  if [ -n "$SINCE_TAG" ]; then
    contributors=$(git log "$SINCE_TAG"..HEAD --format='%an' | sort -u)
  else
    contributors=$(git log --format='%an' | sort -u)
  fi
  while IFS= read -r c; do printf -- '- %s\n' "$c"; done <<< "$contributors"
  printf '\n'
}

CHANGELOG_CONTENT=$(build_changelog)

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}Preview (dry run):${NC}"
  echo ""
  echo "$CHANGELOG_CONTENT"
else
  echo "$CHANGELOG_CONTENT" > "$OUTPUT_FILE"
  echo -e "${GREEN}✓${NC} Changelog written to $OUTPUT_FILE"
  echo ""
  echo "📊 Statistics:"
  echo "  • Features: ${#FEATURES[@]}"
  echo "  • Bug Fixes: ${#FIXES[@]}"
  echo "  • Performance: ${#PERF[@]}"
  echo "  • Documentation: ${#DOCS[@]}"
  [[ "$INCLUDE_ALL" == "true" ]] && echo "  • Other: ${#OTHER[@]}"
  echo "  • Breaking Changes: ${#BREAKING[@]}"
  TOTAL=$((${#FEATURES[@]} + ${#FIXES[@]} + ${#PERF[@]} + ${#DOCS[@]} + ${#OTHER[@]}))
  echo "  • Total Entries: $TOTAL"
fi
