#!/usr/bin/env bash
# ============================================================================
# Claude Code Setup Script for Docker Build
# Dockerビルド時に完全なセットアップを実行
# ============================================================================

set -euo pipefail

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../script-lib"

# Dockerビルド時は /tmp/script-lib を使用
if [[ -d "/tmp/script-lib" ]]; then
    LIB_DIR="/tmp/script-lib"
fi

# shellcheck source=script/lib/output.sh
source "$LIB_DIR/output.sh"
# shellcheck source=script/lib/claude_plugins.sh
source "$LIB_DIR/claude_plugins.sh"

CLAUDE_DIR="/home/vscode/.claude"

main() {
    log_info "Claude Code ビルド時セットアップを開始します..."

    # Claude CLI の存在確認
    if ! command -v claude &> /dev/null; then
        log_warn "Claude CLI が見つかりません。セットアップをスキップします。"
        exit 0
    fi

    # プラグインがインストールされているか確認
    if [[ ! -d "${CLAUDE_DIR}/plugins/marketplaces" ]]; then
        log_warn "プラグインがインストールされていません。"
        exit 0
    fi

    # hookifyパッチの適用
    log_info "hookifyプラグインのパッチを適用中..."
    plugins::apply_hookify_patch "$CLAUDE_DIR"

    # known_marketplaces.json の生成
    if [[ -f "${CLAUDE_DIR}/plugins/known_marketplaces.json.template" ]]; then
        log_info "known_marketplaces.json を生成中..."
        sed "s|{{HOME}}|/home/vscode|g" \
            "${CLAUDE_DIR}/plugins/known_marketplaces.json.template" \
            > "${CLAUDE_DIR}/plugins/known_marketplaces.json"
        log_success "known_marketplaces.json を生成しました"
    fi

    log_success "Claude Code ビルド時セットアップが完了しました！"
}

main "$@"
