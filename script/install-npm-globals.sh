#!/usr/bin/env bash
# ============================================================================
# Install npm global packages from npm/global.json
# ============================================================================
# Codespaces の Node.js feature がグローバルパッケージをリセットするため、
# postCreateCommand でこのスクリプトを実行して再インストール
#
# Usage: ./script/install-npm-globals.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
GLOBAL_JSON="${REPO_ROOT}/npm/global.json"

# shellcheck source=script/lib/output.sh
source "${SCRIPT_DIR}/lib/output.sh"

if [[ ! -f "$GLOBAL_JSON" ]]; then
    error "npm/global.json not found: $GLOBAL_JSON"
    exit 1
fi

# Nix 管理の npm (macOS) は prefix が読み取り専用の Nix store を指すため
# npm install -g できない。CLI ツールは nix/home/packages.nix 側で管理する。
npm_prefix="$(npm config get prefix 2>/dev/null || echo "")"
if [[ "$npm_prefix" == /nix/store/* ]]; then
    warning "npm prefix が読み取り専用の Nix store を指しています: ${npm_prefix}"
    warning "この環境では npm グローバルは管理対象外のためスキップします (nix/home/packages.nix を参照)"
    exit 0
fi

# インストールするパッケージリスト（Node.js feature でリセットされるもの）
PACKAGES=(
    "happy"
    "@openai/codex"
    "@google/gemini-cli"
    "vercel"
)

info "Installing npm global packages from npm/global.json..."

for pkg in "${PACKAGES[@]}"; do
    version=$(node -pe "require('${GLOBAL_JSON}').dependencies['${pkg}']?.version || ''" 2>/dev/null || echo "")

    if [[ -z "$version" ]]; then
        info "Skipping $pkg (not found in global.json)"
        continue
    fi

    # 既にインストール済みかチェック
    installed_version=$(npm list -g "$pkg" --depth=0 2>/dev/null | grep "$pkg@" | sed 's/.*@//' || echo "")

    if [[ "$installed_version" == "$version" ]]; then
        success "$pkg@$version (already installed)"
    else
        info "Installing $pkg@$version..."
        if npm install -g "${pkg}@${version}" --silent 2>/dev/null; then
            success "$pkg@$version"
        else
            error "Failed to install $pkg@$version"
        fi
    fi
done

info "Done!"
