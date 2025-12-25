#!/usr/bin/env bash
# ============================================================================
# Container Plugin Fix Script
# コンテナ内のプラグイン設定を修正し、プラグインをインストールするスクリプト
# ============================================================================

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== コンテナ内プラグイン設定を修正 ===${NC}\n"

# 1. リポジトリの plugins.txt をホームディレクトリにコピー
echo -e "${BLUE}Step 1: plugins.txt を更新${NC}"
if [[ -f /workspaces/config/.claude/plugins/plugins.txt ]]; then
    mkdir -p ~/.claude/plugins
    cp /workspaces/config/.claude/plugins/plugins.txt ~/.claude/plugins/plugins.txt
    echo -e "${GREEN}✓ plugins.txt を更新しました${NC}"
    echo ""
    echo "--- 更新後の内容（最初の15行）---"
    head -15 ~/.claude/plugins/plugins.txt
    echo ""
else
    echo -e "${RED}✗ エラー: リポジトリに plugins.txt が見つかりません${NC}"
    exit 1
fi

# 2. プラグインをインストール
echo -e "${BLUE}Step 2: プラグインをインストール${NC}"
if ! command -v claude &> /dev/null; then
    echo -e "${RED}✗ Claude CLI が見つかりません${NC}"
    exit 1
fi

echo "プラグインをインストール中..."
echo ""

installed=0
failed=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行とコメント行をスキップ
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 前後の空白を除去
    plugin=$(echo "$line" | xargs)
    [[ -z "$plugin" ]] && continue

    echo -n "  Installing: ${plugin}... "

    if claude plugin install "$plugin" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
        installed=$((installed + 1))
    else
        echo -e "${RED}✗${NC}"
        failed=$((failed + 1))
    fi
done < ~/.claude/plugins/plugins.txt

echo ""
echo -e "${GREEN}✓ インストール完了: ${installed} 個${NC}"
if [[ $failed -gt 0 ]]; then
    echo -e "${YELLOW}  失敗/スキップ: ${failed} 個${NC}"
fi

# 3. 確認
echo ""
echo -e "${BLUE}Step 3: 確認${NC}"
INSTALLED_COUNT=$(claude plugin list 2>/dev/null | grep -c "@" || echo "0")
echo "インストール済みプラグイン総数: ${INSTALLED_COUNT}"

echo ""
echo -e "${BLUE}=== 修正完了 ===${NC}"
echo -e "${YELLOW}Tip: '/plugin' コマンドで Installed タブを確認してください${NC}"
