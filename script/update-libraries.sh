#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# npm devDependencies / GitHub Actions / Docker base image updates are managed by Dependabot.
# This script only refreshes the global CLI manifest (npm/global.json) by querying the npm registry,
# because Dependabot cannot parse that custom file format.
GLOBAL_FILE="npm/global.json"

if [[ ! -f "$GLOBAL_FILE" ]]; then
  log_warn "Skipping global CLI manifest update (missing $GLOBAL_FILE)"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to update $GLOBAL_FILE" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to query package versions" >&2
  exit 1
fi

log "Refreshing global CLI manifest versions"
tmp_file=$(mktemp)
cp "$GLOBAL_FILE" "$tmp_file"

declare -a updated_packages=()

while IFS= read -r pkg; do
  current_version=$(jq -r ".dependencies[\"$pkg\"].version" "$GLOBAL_FILE")
  overridden=$(jq -r ".dependencies[\"$pkg\"].overridden // false" "$GLOBAL_FILE")

  if [[ "$overridden" == "true" ]]; then
    log_warn "Skipping $pkg (overridden=true, pinned at $current_version)"
    continue
  fi

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

log_success "Global CLI manifest refresh complete"
