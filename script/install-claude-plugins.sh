#!/usr/bin/env bash
# ============================================================================
# Claude Code Plugin Installer (for Docker build)
# Docker ビルド時にプラグインをインストールするスクリプト
# ライブラリ (claude_plugins.sh) を使用して管理
# ============================================================================

set -euo pipefail

PLUGINS_FILE="${1:-/home/vscode/.claude/plugins/plugins.txt}"
CLAUDE_DIR="/home/vscode/.claude"
CREDENTIALS_SECRET="/run/secrets/claude_credentials"

# --- PATH フォールバック ---
# Dockerfile の ENV PATH で設定されるが、root ユーザーで実行される場合や
# env コマンド経由の場合に PATH が引き継がれないケースがあるため明示的に追加
for _bin_dir in "/home/vscode/.claude/local/bin" "${HOME}/.claude/local/bin"; do
    if [[ ":${PATH}:" != *":${_bin_dir}:"* ]]; then
        export PATH="${_bin_dir}:${PATH}"
    fi
done

# --- ライブラリ読み込み ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR=""

for _candidate in "/tmp/script/lib" "/usr/local/script/lib" "${SCRIPT_DIR}/lib"; do
    if [[ -d "$_candidate" ]] && [[ -f "${_candidate}/output.sh" ]]; then
        LIB_DIR="$_candidate"
        break
    fi
done

if [[ -z "$LIB_DIR" ]]; then
    echo "[ERROR] ライブラリディレクトリが見つかりません"
    exit 1
fi

# shellcheck source=script/lib/output.sh
source "${LIB_DIR}/output.sh"
# shellcheck source=script/lib/claude_plugins.sh
source "${LIB_DIR}/claude_plugins.sh"

log_info "Claude プラグインのインストールを開始します..."

# --- プラグインリスト確認 ---
if [[ ! -f "$PLUGINS_FILE" ]]; then
    log_warn "plugins.txt が見つかりません: ${PLUGINS_FILE}"
    exit 0
fi

# --- 認証情報の設定 ---
mkdir -p "$CLAUDE_DIR"

if [[ -f "$CREDENTIALS_SECRET" ]] && [[ -s "$CREDENTIALS_SECRET" ]]; then
    log_info "BuildKit secret から認証情報を読み込み中..."
    SECRET_CONTENT=$(cat "$CREDENTIALS_SECRET")
    if echo "$SECRET_CONTENT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
        # JSON 形式: そのままコピー
        cp "$CREDENTIALS_SECRET" "${CLAUDE_DIR}/.credentials.json"
    else
        # プレーンテキスト（トークン文字列）: JSON に変換
        log_info "トークン文字列を credentials JSON に変換中..."
        cat > "${CLAUDE_DIR}/.credentials.json" << CRED_EOF
{
  "claudeAiOauth": {
    "accessToken": "${SECRET_CONTENT}",
    "expiresAt": 9999999999999
  }
}
CRED_EOF
    fi
    chmod 600 "${CLAUDE_DIR}/.credentials.json"
elif [[ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]]; then
    log_info "CLAUDE_CODE_OAUTH_TOKEN から認証情報を作成中..."
    cat > "${CLAUDE_DIR}/.credentials.json" << EOF
{
  "claudeAiOauth": {
    "accessToken": "${CLAUDE_CODE_OAUTH_TOKEN}",
    "expiresAt": 9999999999999
  }
}
EOF
elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    log_info "ANTHROPIC_API_KEY から認証情報を作成中..."
    cat > "${CLAUDE_DIR}/.credentials.json" << EOF
{
  "claudeAiOauth": {
    "accessToken": "${ANTHROPIC_API_KEY}",
    "expiresAt": 9999999999999
  }
}
EOF
else
    log_warn "認証情報が見つかりません"
    echo "  - BuildKit secret: $CREDENTIALS_SECRET"
    echo "  - 環境変数: CLAUDE_CODE_OAUTH_TOKEN または ANTHROPIC_API_KEY"
    exit 1
fi

# --- known_marketplaces.json 生成 ---
TEMPLATE="${CLAUDE_DIR}/plugins/known_marketplaces.json.template"
KNOWN_MARKETPLACES="${CLAUDE_DIR}/plugins/known_marketplaces.json"

if [[ -f "$TEMPLATE" ]]; then
    log_info "テンプレートから known_marketplaces.json を生成中..."
    sed "s|{{HOME}}|${HOME}|g" "$TEMPLATE" > "$KNOWN_MARKETPLACES"
    log_success "known_marketplaces.json を生成しました"
fi

# --- Claude CLI 確認 ---
if ! command -v claude &>/dev/null; then
    log_warn "claude コマンドが PATH に見つかりません"
    log_info "PATH: $PATH"
    # which で探索してパスを特定
    CLAUDE_BIN=$(find /home/vscode/.claude/local/bin /usr/local/bin -name claude -type f 2>/dev/null | head -1)
    if [[ -n "$CLAUDE_BIN" ]]; then
        log_info "claude を発見: $CLAUDE_BIN"
        CLAUDE_BIN_DIR="$(dirname "$CLAUDE_BIN")"
        export PATH="${CLAUDE_BIN_DIR}:${PATH}"
    else
        log_warn "claude バイナリが見つかりません。プラグインインストールをスキップします。"
        exit 0
    fi
fi
log_info "Claude version: $(claude --version 2>&1 || echo 'unknown')"

# --- マーケットプレイス追加 ---
plugins::detect_and_add_marketplaces "$PLUGINS_FILE" "$KNOWN_MARKETPLACES"

# --- プラグインインストール ---
plugins::install_from_manifest "$PLUGINS_FILE"

# --- 認証情報を削除（セキュリティ） ---
rm -f "${CLAUDE_DIR}/.credentials.json"

log_success "Claude プラグインのインストールが完了しました"
