#!/bin/sh
set -e

echo "=== Devcontainer feature 'common' installation started ==="

# Check for available environment variables and paths
echo "Available environment variables:"
env | grep -E "(CONTAINER|DEVCONTAINER|_REMOTE|CODESPACE)" || echo "No devcontainer-specific env vars found"

# Try multiple possible paths for the source repository
POSSIBLE_PATHS=(
    "/tmp/build-features"
    "/workspaces"
    "/workspace" 
    "/tmp/tmp"
    "${_CONTAINER_USER_HOME:-/home/vscode}"
    "/src"
)

REPO_ROOT=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path/npm/global.json" ]; then
        REPO_ROOT="$path"
        echo "Found repository at: $REPO_ROOT"
        break
    fi
done

if [ -z "$REPO_ROOT" ]; then
    echo "Could not find npm/global.json in any expected location:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "  Checked: $path/npm/global.json"
        if [ -d "$path" ]; then
            echo "    Directory exists, contents:"
            ls -la "$path" | head -10 || echo "    Cannot list directory"
        else
            echo "    Directory does not exist"
        fi
    done
    echo "Skipping npm package installation."
    exit 0
fi

GLOBAL_JSON_PATH="$REPO_ROOT/npm/global.json"

echo "Installing global npm packages from $GLOBAL_JSON_PATH..."
jq -r '.dependencies | keys[]' "$GLOBAL_JSON_PATH" | while read package; do
    version=$(jq -r ".dependencies[\"$package\"].version" "$GLOBAL_JSON_PATH")
    echo "Installing $package@$version..."
    npm install -g "$package@$version"
done

echo "=== Feature installation completed ==="
