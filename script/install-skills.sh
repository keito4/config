#!/usr/bin/env bash
# ============================================================================
# Claude Code Skills Installer
# skills.txt からスキルをインストールするスクリプト
# ============================================================================

set -euo pipefail

SKILLS_FILE="${1:-/home/vscode/.claude/skills/skills.txt}"
AGENTS_DIR="${HOME}/.agents/skills"

echo "[INFO] Claude スキルのインストールを開始します..."

# スキルリストが存在するか確認
if [[ ! -f "$SKILLS_FILE" ]]; then
    echo "[WARN] skills.txt が見つかりません: ${SKILLS_FILE}"
    exit 0
fi

# npx skills コマンドが利用可能か確認
if ! command -v npx &> /dev/null; then
    echo "[ERROR] npx コマンドが見つかりません"
    exit 1
fi

# スキルディレクトリを作成
mkdir -p "$AGENTS_DIR"

installed=0
failed=0
skipped=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # 空行とコメント行をスキップ
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 前後の空白を除去
    skill=$(echo "$line" | xargs)
    [[ -z "$skill" ]] && continue

    echo "[INFO]   インストール中: ${skill}"

    # スキルがすでにインストールされているか確認
    skill_name=$(basename "$skill")
    if [[ -d "${AGENTS_DIR}/${skill_name}" ]] || [[ -d "${AGENTS_DIR}/vercel-composition-patterns" && "$skill" == "vercel-labs/agent-skills" ]]; then
        echo "[INFO]   スキップ: ${skill} (既にインストール済み)"
        skipped=$((skipped + 1))
        continue
    fi

    # npx skills add でインストール（-y で自動確認、-g でグローバル）
    if output=$(npx skills add "$skill" -y -g 2>&1); then
        echo "[SUCCESS]   完了: ${skill}"
        installed=$((installed + 1))
    else
        # エラーでも継続
        if echo "$output" | grep -qi "already\|exists"; then
            echo "[INFO]   スキップ: ${skill} (既にインストール済み)"
            skipped=$((skipped + 1))
        else
            echo "[WARN]   失敗: ${skill}"
            echo "[WARN]   エラー詳細: ${output}" | head -5
            failed=$((failed + 1))
        fi
    fi
done < "$SKILLS_FILE"

echo "[INFO] スキル: ${installed} インストール完了、${skipped} スキップ、${failed} 失敗"
echo "[SUCCESS] Claude スキルのインストールが完了しました"
