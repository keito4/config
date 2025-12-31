#!/usr/bin/env bash

set -euo pipefail

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_PATH="${REPO_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$REPO_PATH"

log() {
  printf "${BLUE}==> %s${NC}\n" "$1"
}

log_success() {
  printf "${GREEN}✓ %s${NC}\n" "$1"
}

log_warn() {
  printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required to update libraries" >&2
  exit 1
fi

REJECT_PACKAGES=${UPDATE_LIBS_REJECT:-"semantic-release,@semantic-release/github"}
log "Updating npm dependencies with npm-check-updates"
if [[ -n "$REJECT_PACKAGES" ]]; then
  log "Rejecting updates for: $REJECT_PACKAGES"
  npx npm-check-updates --target latest -u --reject "$REJECT_PACKAGES"
else
  npx npm-check-updates --target latest -u
fi

log "Installing updated dependencies"
npm install

GLOBAL_FILE="npm/global.json"
if [[ -f "$GLOBAL_FILE" ]] && command -v jq >/dev/null 2>&1; then
  log "Refreshing global CLI manifest versions"
  tmp_file=$(mktemp)
  cp "$GLOBAL_FILE" "$tmp_file"

  # 更新されたパッケージを追跡
  declare -a updated_packages=()

  while IFS= read -r pkg; do
    current_version=$(jq -r ".dependencies[\"$pkg\"].version" "$GLOBAL_FILE")
    latest_version=$(npm view "$pkg" version 2>/dev/null || echo "$current_version")

    if [[ "$current_version" != "$latest_version" ]]; then
      log_warn "Updating $pkg: $current_version → $latest_version"
      updated_packages+=("$pkg: $current_version → $latest_version")
    fi

    jq --arg pkg "$pkg" --arg version "$latest_version" \
      '.dependencies[$pkg].version = $version' "$tmp_file" >"${tmp_file}.next"
    mv "${tmp_file}.next" "$tmp_file"
  done < <(jq -r '.dependencies | keys[]' "$GLOBAL_FILE")

  mv "$tmp_file" "$GLOBAL_FILE"

  # 更新サマリーを表示
  if [[ ${#updated_packages[@]} -gt 0 ]]; then
    echo ""
    log "Updated packages summary:"
    for update in "${updated_packages[@]}"; do
      echo "  - $update"
    done
    echo ""
  else
    log_success "All global packages are already up to date"
  fi
else
  log "Skipping global CLI manifest update (missing $GLOBAL_FILE or jq)"
fi

log "Running verification pipeline (lint + tests)"
npm run lint
npm test

log_success "Library update complete"

# Claude Code のバージョンを特別に表示
if [[ -f "$GLOBAL_FILE" ]] && command -v jq >/dev/null 2>&1; then
  claude_version=$(jq -r '.dependencies["@anthropic-ai/claude-code"].version' "$GLOBAL_FILE")
  echo ""
  log_success "Claude Code version: ${claude_version}"
  echo ""
fi
