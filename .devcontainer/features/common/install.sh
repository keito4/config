#!/bin/sh
set -e

echo "Starting common feature installation..."

# デバッグ情報を出力
echo "Current working directory: $(pwd)"
echo "User: $(whoami)"
echo "Home directory: $HOME"

# npm/global.jsonを見つけるための複数のパスを試行
GLOBAL_JSON_PATHS=(
    "npm/global.json"
    "/workspace/npm/global.json"
    "/workspaces/*/npm/global.json"
    "$HOME/npm/global.json"
    "/tmp/build/npm/global.json"
)

GLOBAL_JSON_FILE=""
for path in "${GLOBAL_JSON_PATHS[@]}"; do
    # ワイルドカードを展開
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
    for path in "${GLOBAL_JSON_PATHS[@]}"; do
        echo "  - $path"
    done
    echo "Skipping npm package installation."
    exit 0
fi

# jqが利用可能かチェック
if ! command -v jq >/dev/null 2>&1; then
    echo "Installing jq for JSON parsing..."
    apt-get update && apt-get install -y jq
fi

# npm/global.jsonからパッケージを読み込んでインストール
echo "Installing global npm packages from $GLOBAL_JSON_FILE..."
jq -r '.dependencies | keys[]' "$GLOBAL_JSON_FILE" | while read package; do
    version=$(jq -r ".dependencies[\"$package\"].version" "$GLOBAL_JSON_FILE")
    echo "Installing $package@$version..."
    npm install -g "$package@$version"
done

echo "Feature installation completed. Configuration will be applied by postCreateCommand."
