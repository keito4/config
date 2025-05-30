#!/usr/bin/env bash
[ -n "${ZSH_VERSION-}" ] && emulate -L sh
set -euo pipefail

echo "Starting common feature installation..."
echo "Current working directory: $(pwd)"
echo "User: $(whoami)"
echo "Home directory: $HOME"

# npm が無ければ終了
if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found, skipping npm package installation."
  exit 0
fi

# npm キャッシュ
NPM_CACHE_DIR="$HOME/.npm-cache"
mkdir -p "$NPM_CACHE_DIR"
[ -w "$NPM_CACHE_DIR" ] || chown -R "$(id -u):$(id -g)" "$NPM_CACHE_DIR" || true
export NPM_CONFIG_CACHE="$NPM_CACHE_DIR"

# global.json の探索
GLOBAL_JSON_PATHS=(
  "/workspaces/*/npm/global.json"
  "/workspace/npm/global.json"
  "$HOME/npm/global.json"
  "npm/global.json"
)

GLOBAL_JSON_FILE=""

for pattern in "${GLOBAL_JSON_PATHS[@]}"; do
  if [[ "$pattern" == *"*"* ]]; then
    # /workspaces が無い場合はスキップ
    if [ -d /workspaces ]; then
      found=$(find /workspaces -path "$pattern" -type f -print -quit 2>/dev/null || true)
      if [ -n "$found" ]; then
        GLOBAL_JSON_FILE="$found"
        echo "Found npm/global.json at: $GLOBAL_JSON_FILE"
        break
      fi
    fi
  elif [ -f "$pattern" ]; then
    GLOBAL_JSON_FILE="$pattern"
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

packages=$(jq -r '.dependencies | keys[]' "$GLOBAL_JSON_FILE" 2>/dev/null || true)
if [ -n "$packages" ]; then
  echo "Installing npm packages: $packages"
  npm install -g $packages --prefer-offline --no-audit --no-fund --location=user
else
  echo "No packages found in global.json dependencies"
fi

echo "Feature installation completed. Configuration will be applied by postCreateCommand."
