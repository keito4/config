#!/usr/bin/env bash
# ============================================================================
# Claude Code Version Update Script
# Claude Code の最新バージョンに更新します（ネイティブインストーラー使用）
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

log_info "Claude Code バージョン更新を開始します..."

# claudeコマンドの存在確認
if ! command -v claude &> /dev/null; then
    log_error "Claude CLI が見つかりません。"
    log_info "インストール方法: curl -fsSL https://claude.ai/install.sh | bash -s 2.1.25"
    exit 1
fi

# 現在のバージョンを取得
current_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
log_info "現在のバージョン: ${current_version}"

# 更新を実行
log_info "Claude Code を更新中..."

if claude update; then
    new_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
    if [[ "$current_version" == "$new_version" ]]; then
        log_success "Claude Code は既に最新バージョンです (${current_version})"
    else
        log_success "Claude Code を ${current_version} → ${new_version} に更新しました"
    fi
else
    log_warn "claude update に失敗しました。再インストールを試みます..."
    if curl -fsSL https://claude.ai/install.sh | bash -s 2.1.25; then
        new_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
        log_success "Claude Code を再インストールしました (${new_version})"
    else
        log_error "Claude Code の更新に失敗しました"
        exit 1
    fi
fi

# リリースノートのURLを表示
log_info "リリースノート: https://github.com/anthropics/claude-code/releases"

log_success "更新完了！"
