#!/usr/bin/env bash
# ============================================================================
# Post-Create Plugin Installer
# DevContainer 起動後にプラグインが不足している場合に自動インストール
# ============================================================================

set -euo pipefail

PLUGINS_FILE="${1:-/home/vscode/.claude/plugins/plugins.txt}"

echo "[INFO] Claude プラグインの状態を確認中..."

# プラグインリストが存在するか確認
if [[ ! -f "$PLUGINS_FILE" ]]; then
    echo "[WARN] plugins.txt が見つかりません: ${PLUGINS_FILE}"
    exit 0
fi

installed=0
missing=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行とコメント行をスキップ
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 前後の空白を除去
    plugin=$(echo "$line" | xargs)
    [[ -z "$plugin" ]] && continue

    # プラグインがインストール済みかチェック
    if ! claude plugin list 2>/dev/null | grep -q "$plugin"; then
        echo "[INFO] インストール中: ${plugin}"
        if claude plugin install "$plugin" 2>/dev/null; then
            echo "[SUCCESS] 完了: ${plugin}"
            installed=$((installed + 1))
        else
            echo "[WARN] スキップまたは失敗: ${plugin}"
            missing=$((missing + 1))
        fi
    fi
done < "$PLUGINS_FILE"

if [[ $installed -gt 0 ]]; then
    echo "[SUCCESS] ${installed} 個のプラグインをインストールしました"
fi

if [[ $missing -gt 0 ]]; then
    echo "[WARN] ${missing} 個のプラグインのインストールに失敗しました"
    echo "[INFO] 手動でインストールするには: claude plugin install <plugin>@<marketplace>"
fi

exit 0
