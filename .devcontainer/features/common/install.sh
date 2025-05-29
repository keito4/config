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

GLOBAL_JSON_PATHS=(
  "npm/global.json"
  "/workspace/npm/global.json"
  "/workspaces/*/npm/global.json"
  "$HOME/npm/global.json"
  "/tmp/build/npm/global.json"
)

GLOBAL_JSON_FILE=""
for path in ${GLOBAL_JSON_PATHS[@]}; do
  for file in $path; do
    if [ -f "$file" ]; then
      GLOBAL_JSON_FILE="$file"
      echo "Found npm/global.json at: $GLOBAL_JSON_FILE"
      break 2
    fi
  done
done

if [ -z "$GLOBAL_JSON_FILE" ]; then
  echo "Warning: npm/global.json not found in any of the expected locations:"
  for path in ${GLOBAL_JSON_PATHS[@]}; do
    echo "  - $path"
  done
  echo "Skipping npm package installation."
  exit 0
fi

npm install -g $(jq -r '.dependencies | keys[]' "$GLOBAL_JSON_FILE")

echo "Feature installation completed. Configuration will be applied by postCreateCommand."
