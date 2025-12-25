#!/usr/bin/env bash
# ============================================================================
# Container Setup Verification Script
# コンテナ内の設定を確認するスクリプト
# ============================================================================

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== コンテナ内セットアップ確認 ===${NC}\n"

# 1. plugins.txt の内容確認
echo -e "${BLUE}1. plugins.txt の内容確認${NC}"
if [[ -f ~/.claude/plugins/plugins.txt ]]; then
    echo "✓ ファイルが存在します: ~/.claude/plugins/plugins.txt"
    echo ""
    echo "--- 内容（最初の15行）---"
    head -15 ~/.claude/plugins/plugins.txt
    echo ""

    # claude-code-plugins が含まれているかチェック（古い設定）
    if grep -q "claude-code-plugins" ~/.claude/plugins/plugins.txt; then
        echo -e "${RED}✗ 警告: 古いマーケットプレイス名が見つかりました${NC}"
        echo -e "${YELLOW}  setup-claude.sh を実行して更新してください${NC}"
    else
        echo -e "${GREEN}✓ 正しいマーケットプレイス名です${NC}"
    fi
else
    echo -e "${RED}✗ plugins.txt が見つかりません${NC}"
fi

echo ""

# 2. インストール済みプラグインの確認
echo -e "${BLUE}2. インストール済みプラグイン${NC}"
if command -v claude &> /dev/null; then
    echo "✓ Claude CLI が利用可能です"
    echo ""
    # プラグイン数をカウント
    INSTALLED_COUNT=$(claude plugin list 2>/dev/null | grep -c "@" || echo "0")
    echo "インストール済みプラグイン数: ${INSTALLED_COUNT}"
else
    echo -e "${RED}✗ Claude CLI が見つかりません${NC}"
fi

echo ""

# 3. イメージバージョンの確認
echo -e "${BLUE}3. 使用中のイメージ情報${NC}"
if [[ -f /etc/hostname ]]; then
    echo "Hostname: $(cat /etc/hostname)"
fi
echo "User: $(whoami)"
echo "Home: ${HOME}"
echo "Working Directory: $(pwd)"

echo ""

# 4. setup-claude.sh の存在確認
echo -e "${BLUE}4. セットアップスクリプト${NC}"
if [[ -f /workspaces/config/script/setup-claude.sh ]]; then
    echo -e "${GREEN}✓ setup-claude.sh が利用可能です${NC}"
    echo ""
    echo -e "${YELLOW}修正が必要な場合は以下を実行してください:${NC}"
    echo "  cd /workspaces/config"
    echo "  ./script/setup-claude.sh"
else
    echo -e "${RED}✗ setup-claude.sh が見つかりません${NC}"
fi

echo ""
echo -e "${BLUE}=== 確認完了 ===${NC}"
