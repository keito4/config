#!/usr/bin/env bash
# ============================================================================
# Claude Code Setup Script
# ローカル環境/DevContainer両方で動作するプラグインセットアップ
# ============================================================================
# 要件: bash 4.0+ (連想配列を使用)
# macOS: PATH に /opt/homebrew/bin が含まれていること (brew install bash)

set -euo pipefail

# Bash バージョンチェック
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "エラー: このスクリプトは bash 4.0 以降が必要です (現在: ${BASH_VERSION})"
    echo "macOS の場合: brew install bash を実行してください"
    echo "その後、PATH に /opt/homebrew/bin を追加してください"
    exit 1
fi

# Determine script directory and source output library
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/script/lib/output.sh"

# 環境検出とパス設定
CLAUDE_DIR="${HOME}/.claude"
PLUGINS_DIR="${CLAUDE_DIR}/plugins"
PLUGINS_FILE="${PLUGINS_DIR}/plugins.txt"
KNOWN_MARKETPLACES="${PLUGINS_DIR}/known_marketplaces.json"
MARKETPLACES_TEMPLATE="${PLUGINS_DIR}/known_marketplaces.json.template"
REPO_PLUGINS_DIR="${REPO_ROOT}/.claude/plugins"

log_info "Claude Code プラグインセットアップを開始します..."
log_info "環境: HOME=${HOME}"

# 一時ディレクトリを作成（クロスデバイスリンクエラー対策）
mkdir -p "${CLAUDE_DIR}/tmp"
export TMPDIR="${CLAUDE_DIR}/tmp"

# Claude CLI の存在確認
if ! command -v claude &> /dev/null; then
    log_warn "Claude CLI が見つかりません。プラグインのインストールはスキップされます。"
    exit 0
fi

# リポジトリのplugins.txtとテンプレートを$HOME/.claude/pluginsにコピー
log_info "リポジトリからプラグイン設定をコピー中..."
mkdir -p "${PLUGINS_DIR}"

if [[ -f "${REPO_PLUGINS_DIR}/plugins.txt" ]]; then
    cp "${REPO_PLUGINS_DIR}/plugins.txt" "${PLUGINS_FILE}"
    log_success "plugins.txt をコピーしました"
else
    log_warn "リポジトリにplugins.txtが見つかりません"
fi

if [[ -f "${REPO_PLUGINS_DIR}/known_marketplaces.json.template" ]]; then
    cp "${REPO_PLUGINS_DIR}/known_marketplaces.json.template" "${MARKETPLACES_TEMPLATE}"
    log_success "known_marketplaces.json.template をコピーしました"
fi

# テンプレートから known_marketplaces.json を生成
if [[ -f "${MARKETPLACES_TEMPLATE}" ]]; then
    log_info "テンプレートから known_marketplaces.json を生成中..."
    sed "s|{{HOME}}|${HOME}|g" "${MARKETPLACES_TEMPLATE}" > "${KNOWN_MARKETPLACES}"
    log_success "known_marketplaces.json を生成しました"
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

# hookifyプラグインのインポートエラー修正パッチを適用
log_info "hookifyプラグインのインポートパッチを適用中..."
HOOKIFY_MARKETPLACE="${HOME}/.claude/plugins/marketplaces/claude-code-plugins/plugins/hookify"
HOOKIFY_OFFICIAL="${HOME}/.claude/plugins/marketplaces/claude-plugins-official/plugins/hookify"

for HOOKIFY_DIR in "$HOOKIFY_MARKETPLACE" "$HOOKIFY_OFFICIAL"; do
    if [[ -d "$HOOKIFY_DIR" ]]; then
        log_info "  パッチ適用先: ${HOOKIFY_DIR}"

        # 絶対インポートを相対インポートに変更（OS非依存）
        find "$HOOKIFY_DIR" -name "*.py" -type f -exec perl -i -pe \
            's/from hookify\.core/from core/g; s/from hookify\.utils/from utils/g; s/from hookify\.matchers/from matchers/g;' \
            {} \; 2>/dev/null

        # hooks/ディレクトリ内のPythonスクリプトのshebangを修正
        if [[ -d "$HOOKIFY_DIR/hooks" ]]; then
            for py_file in "$HOOKIFY_DIR/hooks"/*.py; do
                if [[ -f "$py_file" ]]; then
                    # shebangを明示的に#!/usr/bin/env python3に設定
                    if head -n1 "$py_file" | grep -q "^#!"; then
                        # 既存のshebangを置換
                        perl -i -pe 's|^#!.*python.*|#!/usr/bin/env python3|' "$py_file"
                    else
                        # shebangがない場合は追加
                        tmp_file=$(mktemp)
                        echo '#!/usr/bin/env python3' > "$tmp_file"
                        cat "$py_file" >> "$tmp_file"
                        mv "$tmp_file" "$py_file"
                    fi
                    chmod +x "$py_file"
                fi
            done
            log_success "  hookスクリプトのshebangを修正しました"
        fi

        # __init__.pyが存在しない場合は作成
        if [[ ! -f "$HOOKIFY_DIR/__init__.py" ]]; then
            cat > "$HOOKIFY_DIR/__init__.py" <<'INIT_EOF'
"""Hookify plugin package.

This package provides hook-based automation for Claude Code.
"""

__version__ = "0.1.0"
INIT_EOF
            log_success "  __init__.pyを作成しました"
        fi
    fi
done

if [[ ! -d "$HOOKIFY_MARKETPLACE" && ! -d "$HOOKIFY_OFFICIAL" ]]; then
    log_info "hookifyプラグインが見つかりません。パッチはスキップします。"
fi

log_success "Claude Code プラグインセットアップが完了しました！"
