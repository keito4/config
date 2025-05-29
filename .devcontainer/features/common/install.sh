#!/usr/bin/env bash
[ -n "${ZSH_VERSION-}" ] && emulate -L sh
set -eu
if (set -o 2>/dev/null | grep -q pipefail); then
  set -o pipefail
fi

echo "Starting common feature installation..."
echo "Current working directory: $(pwd)"
echo "User: $(whoami)"
echo "Home directory: $HOME"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found, skipping npm package installation."
  exit 0
fi

NPM_CACHE_DIR="/tmp/.npm-cache"
mkdir -p "$NPM_CACHE_DIR"
npm config set cache "$NPM_CACHE_DIR" --global

GLOBAL_JSON_PATHS=(
  "/workspaces/*/npm/global.json"
  "/workspace/npm/global.json"
  "$HOME/npm/global.json"
  "npm/global.json"
)

GLOBAL_JSON_FILE=""
for path in "${GLOBAL_JSON_PATHS[@]}"; do
  if [[ "$path" == *"*"* ]]; then
    found_file=$(find / -path "$path" -type f 2>/dev/null | head -n 1)
    if [ -n "$found_file" ]; then
      GLOBAL_JSON_FILE="$found_file"
      echo "Found npm/global.json at: $GLOBAL_JSON_FILE"
      break
    fi
  elif [ -f "$path" ]; then
    GLOBAL_JSON_FILE="$path"
    echo "Found npm/global.json at: $GLOBAL_JSON_FILE"
    break
  fi
done

if [ -z "$GLOBAL_JSON_FILE" ]; then
  echo "Warning: npm/global.json not found in any of the expected locations:"
  printf '  - %s\n' "${GLOBAL_JSON_PATHS[@]}"
  echo "Skipping npm package installation."
  exit 0
fi

packages=$(jq -r '.dependencies | keys[]' "$GLOBAL_JSON_FILE" 2>/dev/null || echo "")
if [ -n "$packages" ]; then
  echo "Installing npm packages: $packages"
  npm install -g $packages --prefer-offline --no-audit --no-fund
else
  echo "No packages found in global.json dependencies"
fi

echo "Feature installation completed. Configuration will be applied by postCreateCommand."
