#!/usr/bin/env bash
# ============================================================================
# Claude Code Version Update Script
# @anthropic-ai/claude-code の最新バージョンをチェックして更新します
# ============================================================================

set -euo pipefail

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GLOBAL_FILE="${PROJECT_ROOT}/npm/global.json"
PACKAGE="@anthropic-ai/claude-code"

log_info "Claude Code バージョン更新を開始します..."

# jqの存在確認
if ! command -v jq &> /dev/null; then
    log_error "jq が必要です。インストールしてください: brew install jq"
    exit 1
fi

# npmの存在確認
if ! command -v npm &> /dev/null; then
    log_error "npm が必要です。"
    exit 1
fi

# global.jsonの存在確認
if [[ ! -f "$GLOBAL_FILE" ]]; then
    log_error "global.json が見つかりません: ${GLOBAL_FILE}"
    exit 1
fi

# 現在のバージョンを取得
current_version=$(jq -r ".dependencies[\"${PACKAGE}\"].version" "$GLOBAL_FILE")
log_info "現在のバージョン: ${current_version}"

# 最新バージョンを取得
log_info "最新バージョンを確認中..."
latest_version=$(npm view "$PACKAGE" version 2>/dev/null)

if [[ -z "$latest_version" ]]; then
    log_error "最新バージョンの取得に失敗しました"
    exit 1
fi

log_info "最新バージョン: ${latest_version}"

# バージョン比較
if [[ "$current_version" == "$latest_version" ]]; then
    log_success "Claude Code は既に最新バージョンです (${current_version})"
    exit 0
fi

log_warn "バージョンが異なります: ${current_version} → ${latest_version}"

# 更新するかどうかを確認（CI環境では自動的に更新）
if [[ "${CI:-false}" != "true" ]] && [[ "${AUTO_UPDATE:-false}" != "true" ]]; then
    read -p "更新しますか? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "更新をキャンセルしました"
        exit 0
    fi
fi

# global.jsonを更新
log_info "global.json を更新中..."
tmp_file=$(mktemp)
jq --arg version "$latest_version" \
  ".dependencies[\"${PACKAGE}\"].version = \$version" "$GLOBAL_FILE" > "$tmp_file"
mv "$tmp_file" "$GLOBAL_FILE"

log_success "Claude Code を ${current_version} → ${latest_version} に更新しました"

# リリースノートのURLを表示
log_info "リリースノート: https://github.com/anthropics/claude-code/releases"

log_success "更新完了！"
