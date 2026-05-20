#!/usr/bin/env bash
# ============================================================================
# Agent Skills Installer
# skills.txt からスキルを全エージェント向けにインストールするスクリプト
# 対象: Claude Code, Codex, Cursor, Gemini CLI
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
PROJECT_AGENTS_DIR="${PWD}/.agents/skills"

echo "[INFO] エージェントスキルのインストールを開始します..."

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

# スキルの存在チェック（グローバルとプロジェクトの両方を確認）
skill_exists() {
    local name="$1"
    [[ -d "${AGENTS_DIR}/${name}" ]] || [[ -d "${PROJECT_AGENTS_DIR}/${name}" ]]
}

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

    # スキルがすでにインストールされているか確認
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
            check_skills=("agent-browser")
            ;;
        "intellectronica/agent-skills")
            check_skills=("context7")
            ;;
        *)
            # @tag 付きエントリ: owner/repo@skill-name → skill-name
            # @tag なしエントリ: owner/repo → basename (repo)
            if [[ "$skill" == */*@* ]]; then
                check_skills=("${skill##*@}")
            else
                check_skills=("$(basename "$skill")")
            fi
            ;;
    esac

    # いずれかのスキルがインストールされているかチェック
    all_installed=true
    for check_skill in "${check_skills[@]}"; do
        if ! skill_exists "$check_skill"; then
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

    # npx skills add でインストール（-y で自動確認、-g でグローバル、-a '*' で全エージェント対応）
    if output=$(npx skills add "$skill" -y -g -a '*' 2>&1); then
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

# Claude Code のローカルファイルを SKILL.md 形式に変換して .agents/skills/ に同期する関数
# 引数: $1=ソースディレクトリ, $2=ラベル（ログ表示用）
sync_claude_to_agents() {
    local src_dir="$1"
    local label="$2"
    local synced=0

    [[ -d "$src_dir" ]] || return 0

    for src_file in "$src_dir"/*.md; do
        [[ -f "$src_file" ]] || continue
        local name
        name="$(basename "$src_file" .md)"
        # README.md はスキップ
        [[ "$name" == "README" ]] && continue

        local target_dir="${PROJECT_AGENTS_DIR}/${name}"
        local target_file="${target_dir}/SKILL.md"

        # frontmatter の有無を判定
        local has_frontmatter
        has_frontmatter=$(head -1 "$src_file" | grep -c '^---$' || true)

        local description body
        if [[ "$has_frontmatter" -gt 0 ]]; then
            # frontmatter から description を抽出
            description=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: */, ""); print; exit}' "$src_file")
            # frontmatter の後の本文を取得（2つ目の --- 以降）
            body=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$src_file")
            # description が空なら本文の最初の見出しをフォールバック
            if [[ -z "$description" ]]; then
                description=$(echo "$body" | awk '/^#+ /{sub(/^#+ */, ""); print; exit}')
            fi
        else
            # frontmatter なし: 最初の # 見出しを description として使用
            description=$(awk '/^#+ /{sub(/^#+ */, ""); print; exit}' "$src_file")
            body=$(cat "$src_file")
        fi

        # description が空の場合はスキル名をフォールバック
        [[ -z "$description" ]] && description="$name"

        mkdir -p "$target_dir"
        printf '%s\n' "---" \
            "name: ${name}" \
            "description: ${description}" \
            "metadata:" \
            "  author: keito4" \
            "  version: \"1.0.0\"" \
            "---" > "$target_file"
        printf '%s\n' "$body" >> "$target_file"

        echo "[INFO]   ${label}同期: ${name} → ${target_dir}"
        synced=$((synced + 1))
    done
    echo "[INFO] ${label}: ${synced} 件同期完了"
}

# カスタムスキル（.claude/skills/*.md）を同期
CLAUDE_SKILLS_DIR=""
if [[ -n "$SKILLS_FILE" ]]; then
    CLAUDE_SKILLS_DIR="$(dirname "$SKILLS_FILE")"
elif [[ -d "${PWD}/.claude/skills" ]]; then
    CLAUDE_SKILLS_DIR="${PWD}/.claude/skills"
fi
sync_claude_to_agents "${CLAUDE_SKILLS_DIR:-}" "カスタムスキル"

# コマンド（.claude/commands/*.md）をスキルとして同期
CLAUDE_COMMANDS_DIR=""
if [[ -n "$CLAUDE_SKILLS_DIR" ]]; then
    CLAUDE_COMMANDS_DIR="$(dirname "$CLAUDE_SKILLS_DIR")/commands"
elif [[ -d "${PWD}/.claude/commands" ]]; then
    CLAUDE_COMMANDS_DIR="${PWD}/.claude/commands"
fi
sync_claude_to_agents "${CLAUDE_COMMANDS_DIR:-}" "コマンド"

# ルール（.claude/rules/*.md）をスキルとして同期
CLAUDE_RULES_DIR=""
if [[ -n "$CLAUDE_SKILLS_DIR" ]]; then
    CLAUDE_RULES_DIR="$(dirname "$CLAUDE_SKILLS_DIR")/rules"
elif [[ -d "${PWD}/.claude/rules" ]]; then
    CLAUDE_RULES_DIR="${PWD}/.claude/rules"
fi
sync_claude_to_agents "${CLAUDE_RULES_DIR:-}" "ルール"

# コマンドを Codex prompts（/command で呼び出し可能）にシンボリックリンク
# .codex/prompts/<name>.md → .claude/commands/<name>.md
CODEX_PROMPTS_DIR="${PWD}/.codex/prompts"
if [[ -n "${CLAUDE_COMMANDS_DIR:-}" && -d "$CLAUDE_COMMANDS_DIR" ]]; then
    mkdir -p "$CODEX_PROMPTS_DIR"
    prompts_synced=0
    for cmd_file in "$CLAUDE_COMMANDS_DIR"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        cmd_name="$(basename "$cmd_file")"
        [[ "$cmd_name" == "README.md" ]] && continue
        link_path="${CODEX_PROMPTS_DIR}/${cmd_name}"
        [[ -e "$link_path" || -L "$link_path" ]] && continue
        ln -s "../../.claude/commands/${cmd_name}" "$link_path"
        prompts_synced=$((prompts_synced + 1))
    done
    echo "[INFO] Codex prompts: ${prompts_synced} 件リンク作成"
fi

# .agents/skills/ のスキルを各エージェントのスキルディレクトリにシンボリックリンク
# Codex (.codex/skills/), Cursor (.cursor/skills/), Gemini (.gemini/skills/) 等
# 対象: プロジェクトレベル (.agents/skills/) の全スキル + カスタムスキル
# グローバル (~/.agents/skills/) は skills.txt 外のスキルを含むため全量リンクしない
AGENT_SKILL_DIRS=(".codex/skills" ".cursor/skills" ".gemini/skills")
linked=0

# リンク対象スキル名を収集（プロジェクトレベル + カスタムスキル、重複排除）
declare -A all_skills
# プロジェクトレベルのスキル（npx skills add で project に入ったもの）
if [[ -d "$PROJECT_AGENTS_DIR" ]]; then
    for skill_dir in "${PROJECT_AGENTS_DIR}"/*/; do
        [[ -d "$skill_dir" ]] || continue
        all_skills["$(basename "$skill_dir")"]=1
    done
fi
# カスタムスキル + コマンド + ルール（プロジェクトに同期済み）
for src_dir in "${CLAUDE_SKILLS_DIR:-}" "${CLAUDE_COMMANDS_DIR:-}" "${CLAUDE_RULES_DIR:-}"; do
    [[ -n "$src_dir" && -d "$src_dir" ]] || continue
    for skill_file in "$src_dir"/*.md; do
        [[ -f "$skill_file" ]] || continue
        skill_name="$(basename "$skill_file" .md)"
        [[ "$skill_name" == "README" ]] && continue
        all_skills["$skill_name"]=1
    done
done

for agent_dir in "${AGENT_SKILL_DIRS[@]}"; do
    target_base="${PWD}/${agent_dir}"
    mkdir -p "$target_base"
    for skill_name in "${!all_skills[@]}"; do
        link_path="${target_base}/${skill_name}"
        # 既にリンクまたはディレクトリが存在する場合はスキップ（-L で壊れたリンクも検出）
        if [[ -e "$link_path" || -L "$link_path" ]]; then
            continue
        fi
        # プロジェクトレベルを優先、なければグローバルへリンク
        # 相対パスはエージェントディレクトリが2階層深い前提（.codex/skills/, .cursor/skills/ 等）
        if [[ -d "${PROJECT_AGENTS_DIR}/${skill_name}" ]]; then
            ln -s "../../.agents/skills/${skill_name}" "$link_path"
        elif [[ -d "${AGENTS_DIR}/${skill_name}" ]]; then
            ln -s "${AGENTS_DIR}/${skill_name}" "$link_path"
        else
            continue
        fi
        echo "[INFO]   リンク作成: ${agent_dir}/${skill_name}"
        linked=$((linked + 1))
    done
done
echo "[INFO] シンボリックリンク: ${linked} 件作成"

echo "[SUCCESS] エージェントスキルのインストールが完了しました"
