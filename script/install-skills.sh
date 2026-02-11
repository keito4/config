#!/usr/bin/env bash
# ============================================================================
# Claude Code Skills Installer
# skills.txt からスキルをインストールするスクリプト
# ============================================================================

set -euo pipefail

# skills.txt のパスを決定（引数 > ワークスペース > ホームディレクトリ）
if [[ -n "${1:-}" ]]; then
    SKILLS_FILE="$1"
elif [[ -f "${PWD}/.claude/skills/skills.txt" ]]; then
    SKILLS_FILE="${PWD}/.claude/skills/skills.txt"
elif [[ -f "/home/vscode/.claude/skills/skills.txt" ]]; then
    SKILLS_FILE="/home/vscode/.claude/skills/skills.txt"
else
    SKILLS_FILE=""
fi

AGENTS_DIR="${HOME}/.agents/skills"

echo "[INFO] Claude スキルのインストールを開始します..."

# スキルリストが存在するか確認
if [[ -z "$SKILLS_FILE" ]] || [[ ! -f "$SKILLS_FILE" ]]; then
    echo "[WARN] skills.txt が見つかりません"
    exit 0
fi

echo "[INFO] 使用するスキルリスト: ${SKILLS_FILE}"

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

    echo "[INFO]   チェック中: ${skill}"

    # スキルがすでにインストールされているか npx skills list -g で確認
    # 既知のリポジトリとスキル名のマッピング
    case "$skill" in
        "vercel-labs/agent-skills")
            check_skills=("vercel-composition-patterns" "vercel-react-best-practices" "vercel-react-native-skills" "web-design-guidelines")
            ;;
        "supabase/agent-skills")
            check_skills=("supabase-postgres-best-practices")
            ;;
        "vercel-labs/skills")
            check_skills=("find-skills")
            ;;
        "vercel-labs/agent-browser")
            check_skills=("agent-browser" "skill-creator")
            ;;
        *)
            # 不明なリポジトリは basename を使用
            check_skills=("$(basename "$skill")")
            ;;
    esac

    # いずれかのスキルがインストールされているかチェック
    all_installed=true
    for check_skill in "${check_skills[@]}"; do
        if [[ ! -d "${AGENTS_DIR}/${check_skill}" ]]; then
            all_installed=false
            break
        fi
    done

    if $all_installed; then
        echo "[INFO]   スキップ: ${skill} (既にインストール済み)"
        skipped=$((skipped + 1))
        continue
    fi

    echo "[INFO]   インストール中: ${skill}"

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
