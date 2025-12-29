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
KNOWN_MARKETPLACES="/home/vscode/.claude/plugins/known_marketplaces.json"

log_info "Claude Code プラグインセットアップを開始します..."

# 一時ディレクトリを作成（クロスデバイスリンクエラー対策）
mkdir -p /home/vscode/.claude/tmp
export TMPDIR=/home/vscode/.claude/tmp

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

# マーケットプレイスの自動検出と初期化
log_info "マーケットプレイスを自動検出して初期化中..."

# plugins.txtから必要なマーケットプレイスを抽出
declare -A marketplaces_needed
while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行とコメント行をスキップ
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # マーケットプレイス名を抽出（@以降の部分）
    if [[ "$line" =~ @([^[:space:]]+) ]]; then
        marketplace="${BASH_REMATCH[1]}"
        marketplaces_needed["$marketplace"]=1
    fi
done < "$PLUGINS_FILE"

# known_marketplaces.jsonから各マーケットプレイスのURLを取得してインストール
if [[ -f "$KNOWN_MARKETPLACES" ]]; then
    for marketplace in "${!marketplaces_needed[@]}"; do
        # jqを使用してマーケットプレイス情報を取得
        if command -v jq &> /dev/null; then
            repo=$(jq -r ".\"$marketplace\".source.repo // empty" "$KNOWN_MARKETPLACES" 2>/dev/null)
            url=$(jq -r ".\"$marketplace\".source.url // empty" "$KNOWN_MARKETPLACES" 2>/dev/null)

            if [[ -n "$repo" ]]; then
                # GitHubリポジトリ形式
                claude plugin marketplace add "https://github.com/${repo}.git" 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
            elif [[ -n "$url" ]]; then
                # URL形式
                claude plugin marketplace add "$url" 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
            else
                log_warn "  ${marketplace}: マーケットプレイス情報が見つかりません"
            fi
        else
            # jqがない場合は従来の固定リストを使用
            case "$marketplace" in
                "claude-plugins-official")
                    claude plugin marketplace add https://github.com/anthropics/claude-plugins-official.git 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
                    ;;
                "claude-code-plugins")
                    claude plugin marketplace add https://github.com/anthropics/claude-code.git 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
                    ;;
                "claude-code-workflows")
                    claude plugin marketplace add https://github.com/wshobson/agents.git 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
                    ;;
                "claude-code-templates")
                    claude plugin marketplace add https://github.com/davila7/claude-code-templates.git 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
                    ;;
                "playwright-skill")
                    claude plugin marketplace add https://github.com/lackeyjb/playwright-skill.git 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
                    ;;
                *)
                    log_warn "  ${marketplace}: 未知のマーケットプレイス"
                    ;;
            esac
        fi
    done
else
    log_warn "known_marketplaces.json が見つかりません。デフォルトのマーケットプレイスを使用します。"
    # デフォルトのマーケットプレイス
    claude plugin marketplace add https://github.com/anthropics/claude-plugins-official.git 2>/dev/null || log_info "  claude-plugins-official: 既に追加済み"
    claude plugin marketplace add https://github.com/anthropics/claude-code.git 2>/dev/null || log_info "  claude-code-plugins: 既に追加済み"
    claude plugin marketplace add https://github.com/wshobson/agents.git 2>/dev/null || log_info "  claude-code-workflows: 既に追加済み"
    claude plugin marketplace add https://github.com/davila7/claude-code-templates.git 2>/dev/null || log_info "  claude-code-templates: 既に追加済み"
fi

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
