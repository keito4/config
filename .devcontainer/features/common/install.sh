#!/bin/sh
set -e

# npm/global.jsonからパッケージを読み込んでインストール
if [ -f "npm/global.json" ]; then
    echo "Installing global npm packages from npm/global.json..."
    jq -r '.dependencies | keys[]' npm/global.json | while read package; do
        version=$(jq -r ".dependencies[\"$package\"].version" npm/global.json)
        echo "Installing $package@$version..."
        npm install -g "$package@$version"
    done
fi

echo "Feature installation completed. Configuration will be applied by postCreateCommand."
