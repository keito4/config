#!/usr/bin/env bash
# ============================================================================
# Claude Code Plugin Installer (for Docker build)
# Docker ビルド時にプラグインをインストールするスクリプト
# ============================================================================

set -euo pipefail

PLUGINS_FILE="${1:-/home/vscode/.claude/plugins/plugins.txt}"
CLAUDE_DIR="/home/vscode/.claude"
CREDENTIALS_SECRET="/run/secrets/claude_credentials"

echo "[INFO] Claude プラグインのインストールを開始します..."

# プラグインリストが存在するか確認
if [[ ! -f "$PLUGINS_FILE" ]]; then
    echo "[WARN] plugins.txt が見つかりません: ${PLUGINS_FILE}"
    exit 0
fi

# 認証情報の設定
mkdir -p "$CLAUDE_DIR"

# 方法1: BuildKit secret からコピー（推奨）
if [[ -f "$CREDENTIALS_SECRET" ]]; then
    echo "[INFO] BuildKit secret から認証情報を読み込み中..."
    cp "$CREDENTIALS_SECRET" "${CLAUDE_DIR}/.credentials.json"
    chmod 600 "${CLAUDE_DIR}/.credentials.json"
# 方法2: 環境変数から作成（API キー）
elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "[INFO] ANTHROPIC_API_KEY から認証情報を作成中..."
    cat > "${CLAUDE_DIR}/.credentials.json" << EOF
{
  "claudeAiOauth": {
    "accessToken": "${ANTHROPIC_API_KEY}",
    "expiresAt": 9999999999999
  }
}
EOF
else
    echo "[ERROR] 認証情報が見つかりません"
    echo "  - BuildKit secret: $CREDENTIALS_SECRET"
    echo "  - 環境変数: ANTHROPIC_API_KEY"
    exit 1
fi

echo "[INFO] マーケットプレイスを初期化中..."
# known_marketplaces.jsonから必要なマーケットプレイスを追加
if [[ -f "${CLAUDE_DIR}/plugins/known_marketplaces.json" ]]; then
    echo "[INFO] known_marketplaces.jsonが見つかりました"

    # 必須マーケットプレイスを追加（完全なHTTPS URLを使用）
    claude plugin marketplace add https://github.com/anthropics/claude-code.git 2>&1 || echo "[WARN] claude-code-plugins already exists or failed to add"
    claude plugin marketplace add https://github.com/davila7/claude-code-templates.git 2>&1 || echo "[WARN] claude-code-templates already exists or failed to add"
    claude plugin marketplace add https://github.com/wshobson/agents.git 2>&1 || echo "[WARN] claude-code-workflows already exists or failed to add"
else
    echo "[WARN] known_marketplaces.jsonが見つかりません"
fi

echo "[INFO] プラグインをインストール中..."
echo "[DEBUG] Claude version: $(claude --version 2>&1 || echo 'not found')"
echo "[DEBUG] Marketplaces directory: ${CLAUDE_DIR}/plugins/marketplaces"
ls -la "${CLAUDE_DIR}/plugins/marketplaces" 2>/dev/null || echo "[WARN] Marketplaces directory not found"

installed=0
failed=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行とコメント行をスキップ
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 前後の空白を除去
    plugin=$(echo "$line" | xargs)
    [[ -z "$plugin" ]] && continue

    echo "[INFO]   インストール中: ${plugin}"

    # エラー出力をキャプチャ
    if output=$(claude plugin install "$plugin" 2>&1); then
        echo "[SUCCESS]   完了: ${plugin}"
        installed=$((installed + 1))
    else
        echo "[ERROR]   失敗: ${plugin}"
        echo "[ERROR]   エラー詳細: ${output}"
        failed=$((failed + 1))
    fi
done < "$PLUGINS_FILE"

# 認証情報を削除（セキュリティのため）
rm -f "${CLAUDE_DIR}/.credentials.json"

echo "[INFO] プラグイン: ${installed} インストール完了、${failed} 失敗/スキップ"
echo "[SUCCESS] Claude プラグインのインストールが完了しました"
