#!/usr/bin/env bash
# ============================================================================
# Claude Code Setup Script
# DevContainer 起動時にプラグインをユーザースコープでインストールします
# ============================================================================

set -euo pipefail

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# DevContainer内の固定パスを使用
PLUGINS_FILE="/home/vscode/.claude/plugins/plugins.txt"

log_info "Claude Code プラグインセットアップを開始します..."

# Claude CLI の存在確認
if ! command -v claude &> /dev/null; then
    log_warn "Claude CLI が見つかりません。プラグインのインストールはスキップされます。"
    exit 0
fi

# plugins.txt の存在確認
if [[ ! -f "$PLUGINS_FILE" ]]; then
    log_warn "plugins.txt が見つかりません: ${PLUGINS_FILE}"
    exit 0
fi

# マーケットプレイスの初期化
log_info "マーケットプレイスを初期化中..."
claude plugin marketplace add https://github.com/anthropics/claude-plugins-official.git 2>/dev/null || log_info "  claude-plugins-official: 既に追加済み"
claude plugin marketplace add https://github.com/anthropics/claude-code.git 2>/dev/null || log_info "  claude-code-plugins: 既に追加済み"
claude plugin marketplace add https://github.com/wshobson/agents.git 2>/dev/null || log_info "  claude-code-workflows: 既に追加済み"
claude plugin marketplace add https://github.com/davila7/claude-code-templates.git 2>/dev/null || log_info "  claude-code-templates: 既に追加済み"

log_info "プラグインをユーザースコープでインストール中..."

installed=0
failed=0
skipped=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行とコメント行をスキップ
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 前後の空白を除去
    plugin=$(echo "$line" | xargs)
    [[ -z "$plugin" ]] && continue

    log_info "  インストール中: ${plugin}"

    # ユーザースコープでインストール（デフォルト）
    # エラー出力をキャプチャして詳細を確認
    if output=$(claude plugin install "$plugin" 2>&1); then
        log_success "  完了: ${plugin}"
        installed=$((installed + 1))
    else
        # エラーメッセージから既にインストール済みかチェック
        if echo "$output" | grep -q "already installed\|already exists"; then
            log_info "  スキップ: ${plugin} (既にインストール済み)"
            skipped=$((skipped + 1))
        else
            log_warn "  失敗: ${plugin}"
            echo "    エラー: $output" | head -3
            failed=$((failed + 1))
        fi
    fi
done < "$PLUGINS_FILE"

log_info "プラグイン: ${installed} インストール完了、${skipped} スキップ、${failed} 失敗"
log_success "Claude Code プラグインセットアップが完了しました！"
