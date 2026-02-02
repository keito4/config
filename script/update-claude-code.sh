#!/usr/bin/env bash
# ============================================================================
# Claude Code Version Update Script
# Claude Code のネイティブインストーラー経由でアップデートします
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

log_info "Claude Code アップデートを開始します..."

# Claude CLIの存在確認
if ! command -v claude &> /dev/null; then
    log_error "Claude CLI が見つかりません。"
    log_info "インストール方法: claude install"
    log_info "詳細: https://docs.anthropic.com/en/docs/claude-code/getting-started"
    exit 1
fi

# 現在のバージョンを取得
current_version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
log_info "現在のバージョン: ${current_version}"

# アップデート確認と実行
log_info "Claude Code をアップデート中..."

if claude update; then
    # 更新後のバージョンを取得
    new_version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")

    if [[ "$current_version" == "$new_version" ]]; then
        log_success "Claude Code は既に最新バージョンです (${current_version})"
    else
        log_success "Claude Code を ${current_version} → ${new_version} にアップデートしました"
    fi
else
    log_error "アップデートに失敗しました"
    log_info "手動でアップデートを試してください: claude update"
    exit 1
fi

# リリースノートのURLを表示
log_info "リリースノート: https://github.com/anthropics/claude-code/releases"

log_success "アップデート完了！"
