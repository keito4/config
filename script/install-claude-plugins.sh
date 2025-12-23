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

echo "[INFO] プラグインをインストール中..."

installed=0
failed=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行とコメント行をスキップ
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 前後の空白を除去
    plugin=$(echo "$line" | xargs)
    [[ -z "$plugin" ]] && continue

    echo "[INFO]   インストール中: ${plugin}"

    if claude plugin install "$plugin" 2>/dev/null; then
        echo "[SUCCESS]   完了: ${plugin}"
        installed=$((installed + 1))
    else
        echo "[WARN]   スキップまたは失敗: ${plugin}"
        failed=$((failed + 1))
    fi
done < "$PLUGINS_FILE"

# 認証情報を削除（セキュリティのため）
rm -f "${CLAUDE_DIR}/.credentials.json"

echo "[INFO] プラグイン: ${installed} インストール完了、${failed} 失敗/スキップ"
echo "[SUCCESS] Claude プラグインのインストールが完了しました"
