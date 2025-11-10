#!/usr/bin/env bash

set -euo pipefail

REPO_PATH="${REPO_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$REPO_PATH"

log() {
  printf '==> %s\n' "$1"
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

  while IFS= read -r pkg; do
    latest_version=$(npm view "$pkg" version)
    jq --arg pkg "$pkg" --arg version "$latest_version" \
      '.dependencies[$pkg].version = $version' "$tmp_file" >"${tmp_file}.next"
    mv "${tmp_file}.next" "$tmp_file"
  done < <(jq -r '.dependencies | keys[]' "$GLOBAL_FILE")

  mv "$tmp_file" "$GLOBAL_FILE"
else
  log "Skipping global CLI manifest update (missing $GLOBAL_FILE or jq)"
fi

log "Running build pipeline (includes lint + tests)"
npm run build

log "Library update complete"
