#!/usr/bin/env zsh
# ============================================================================
# Codespaces Secrets Repository Management
# ============================================================================
# GUI を使わずに GitHub Codespaces シークレットのリポジトリ紐付けを管理
# 設定ファイルは ~/.config/codespaces-secrets/ に配置（Git管理外）
#
# Usage:
#   ./script/codespaces-secrets.sh list          - シークレットと紐付けリポジトリを表示
#   ./script/codespaces-secrets.sh repos         - 管理対象リポジトリ一覧を表示
#   ./script/codespaces-secrets.sh repos add     - リポジトリを追加
#   ./script/codespaces-secrets.sh repos remove  - リポジトリを削除
#   ./script/codespaces-secrets.sh sync          - 全シークレットにリポジトリを紐付け
#   ./script/codespaces-secrets.sh sync SECRET   - 特定のシークレットにリポジトリを紐付け
#   ./script/codespaces-secrets.sh init          - 設定ファイルを初期化
#   ./script/codespaces-secrets.sh diff          - 現在の状態と設定ファイルの差分を表示

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SCRIPT_NAME="${0:t}"
source "$SCRIPT_DIR/lib/output.sh"

# 設定ファイルの場所（Git管理外）
CONFIG_DIR="${CODESPACES_SECRETS_CONFIG_DIR:-$HOME/.config/codespaces-secrets}"
REPOS_FILE="$CONFIG_DIR/repos.txt"

# ============================================================================
# Helper Functions
# ============================================================================

ensure_gh_auth() {
    if ! gh auth status >/dev/null 2>&1; then
        output::fatal "GitHub CLI が認証されていません。'gh auth login' を実行してください"
    fi
}

ensure_config_dir() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        output::info "設定ディレクトリを作成しました: $CONFIG_DIR"
    fi
}

ensure_repos_file() {
    ensure_config_dir
    if [[ ! -f "$REPOS_FILE" ]]; then
        touch "$REPOS_FILE"
        output::info "リポジトリ設定ファイルを作成しました: $REPOS_FILE"
    fi
}

get_configured_repos() {
    if [[ -f "$REPOS_FILE" ]]; then
        grep -v '^#' "$REPOS_FILE" | grep -v '^$' | sort -u
    fi
}

get_repo_id() {
    local repo_name="$1"
    gh api "repos/$repo_name" --jq '.id' 2>/dev/null || echo ""
}

get_all_secrets() {
    gh api user/codespaces/secrets --jq '.secrets[].name' 2>/dev/null
}

get_secret_repos() {
    local secret_name="$1"
    gh api "user/codespaces/secrets/$secret_name/repositories" --jq '.repositories[].full_name' 2>/dev/null | sort
}

# ============================================================================
# Commands
# ============================================================================

cmd_list() {
    output::header "Codespaces シークレット一覧"
    echo

    local secrets
    secrets=$(get_all_secrets)

    if [[ -z "$secrets" ]]; then
        output::warning "シークレットが見つかりません"
        return 0
    fi

    local _repos
    while IFS= read -r secret; do
        echo -e "${OUTPUT_GREEN}$secret${OUTPUT_NC}"

        _repos=$(get_secret_repos "$secret")

        if [[ -n "$_repos" ]]; then
            while IFS= read -r repo; do
                echo "  - $repo"
            done <<< "$_repos"
        else
            echo "  (リポジトリ未設定)"
        fi
        echo
    done <<< "$secrets"
}

cmd_repos() {
    local subcommand="${1:-list}"
    [[ $# -gt 0 ]] && shift

    case "$subcommand" in
        list)
            output::header "管理対象リポジトリ一覧"
            echo "設定ファイル: $REPOS_FILE"
            echo

            local repos
            repos=$(get_configured_repos)

            if [[ -z "$repos" ]]; then
                output::warning "リポジトリが設定されていません"
                echo "追加するには: $SCRIPT_NAME repos add owner/repo"
                return 0
            fi

            while IFS= read -r repo; do
                echo "  - $repo"
            done <<< "$repos"
            ;;

        add)
            if [[ $# -eq 0 ]]; then
                output::fatal "リポジトリ名を指定してください (例: owner/repo)"
            fi

            ensure_repos_file

            for repo in "$@"; do
                # リポジトリの存在確認
                if ! gh api "repos/$repo" >/dev/null 2>&1; then
                    output::warning "リポジトリが見つかりません: $repo"
                    continue
                fi

                # 既に登録されているか確認
                if grep -qx "$repo" "$REPOS_FILE" 2>/dev/null; then
                    output::warning "既に登録済み: $repo"
                    continue
                fi

                echo "$repo" >> "$REPOS_FILE"
                output::success "追加しました: $repo"
            done
            ;;

        remove)
            if [[ $# -eq 0 ]]; then
                output::fatal "リポジトリ名を指定してください (例: owner/repo)"
            fi

            if [[ ! -f "$REPOS_FILE" ]]; then
                output::fatal "設定ファイルが存在しません"
            fi

            for repo in "$@"; do
                if grep -qx "$repo" "$REPOS_FILE" 2>/dev/null; then
                    # macOS と Linux の両方で動作するsed
                    if [[ "$(uname)" == "Darwin" ]]; then
                        sed -i '' "/^${repo//\//\\/}$/d" "$REPOS_FILE"
                    else
                        sed -i "/^${repo//\//\\/}$/d" "$REPOS_FILE"
                    fi
                    output::success "削除しました: $repo"
                else
                    output::warning "登録されていません: $repo"
                fi
            done
            ;;

        edit)
            ensure_repos_file
            "${EDITOR:-vim}" "$REPOS_FILE"
            ;;

        *)
            output::fatal "不明なサブコマンド: $subcommand"
            ;;
    esac
}

cmd_sync() {
    local target_secret="${1:-}"

    local repos
    repos=$(get_configured_repos)

    if [[ -z "$repos" ]]; then
        output::fatal "同期するリポジトリが設定されていません。'$SCRIPT_NAME repos add owner/repo' で追加してください"
    fi

    # リポジトリIDを取得
    output::info "リポジトリIDを取得中..."
    local repo_ids=()
    local _repo_id

    while IFS= read -r repo; do
        _repo_id=$(get_repo_id "$repo")

        if [[ -z "$_repo_id" ]]; then
            output::warning "リポジトリIDを取得できません: $repo"
            continue
        fi

        repo_ids+=("$_repo_id")
        output::info "  $repo -> $_repo_id"
    done <<< "$repos"

    if [[ ${#repo_ids[@]} -eq 0 ]]; then
        output::fatal "有効なリポジトリがありません"
    fi

    # JSON配列を作成（数値として）
    local repo_ids_json
    repo_ids_json=$(printf '%s\n' "${repo_ids[@]}" | jq -R 'tonumber' | jq -s .)

    # シークレットを同期
    local secrets
    if [[ -n "$target_secret" ]]; then
        secrets="$target_secret"
    else
        secrets=$(get_all_secrets)
    fi

    if [[ -z "$secrets" ]]; then
        output::fatal "シークレットが見つかりません"
    fi

    output::header "シークレットにリポジトリを紐付け中"
    echo

    while IFS= read -r secret; do
        echo -n "  $secret: "

        if gh api "user/codespaces/secrets/$secret/repositories" \
            -X PUT \
            --input - <<< "{\"selected_repository_ids\": $repo_ids_json}" >/dev/null 2>&1; then
            echo -e "${OUTPUT_GREEN}OK${OUTPUT_NC}"
        else
            echo -e "${OUTPUT_RED}FAILED${OUTPUT_NC}"
        fi
    done <<< "$secrets"

    echo
    output::success "同期完了"
}

cmd_init() {
    output::header "設定ファイルを初期化"

    ensure_config_dir

    if [[ -f "$REPOS_FILE" ]]; then
        output::warning "設定ファイルが既に存在します: $REPOS_FILE"
        echo -n "上書きしますか? [y/N]: "
        read -r answer
        if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
            output::info "キャンセルしました"
            return 0
        fi
    fi

    # 現在紐付けられているリポジトリを収集
    output::info "現在のシークレット設定を取得中..."

    local all_repos=()
    local secrets _repos
    secrets=$(get_all_secrets)

    while IFS= read -r secret; do
        _repos=$(get_secret_repos "$secret")
        if [[ -n "$_repos" ]]; then
            while IFS= read -r repo; do
                all_repos+=("$repo")
            done <<< "$_repos"
        fi
    done <<< "$secrets"

    # 重複を除去してファイルに書き込み
    {
        echo "# Codespaces Secrets - 管理対象リポジトリ"
        echo "# このファイルは Git 管理外です"
        echo "# 1行1リポジトリ（owner/repo 形式）"
        echo "#"
        echo "# 使用方法:"
        echo "#   ./script/codespaces-secrets.sh sync  - 全シークレットにこのリストを紐付け"
        echo "#"
        printf '%s\n' "${all_repos[@]}" | sort -u
    } > "$REPOS_FILE"

    output::success "設定ファイルを作成しました: $REPOS_FILE"
    echo
    echo "登録されたリポジトリ:"
    printf '%s\n' "${all_repos[@]}" | sort -u | sed 's/^/  - /'
}

cmd_diff() {
    output::header "設定と現在の状態の差分"
    echo

    local configured_repos
    configured_repos=$(get_configured_repos)

    if [[ -z "$configured_repos" ]]; then
        output::warning "設定ファイルにリポジトリがありません"
        return 0
    fi

    local secrets current_repos missing_repos extra_repos
    secrets=$(get_all_secrets)

    while IFS= read -r secret; do
        echo -e "${OUTPUT_BLUE}$secret${OUTPUT_NC}"

        current_repos=$(get_secret_repos "$secret")

        # 差分を計算
        missing_repos=$(comm -23 <(echo "$configured_repos" | sort) <(echo "$current_repos" | sort) 2>/dev/null || true)
        extra_repos=$(comm -13 <(echo "$configured_repos" | sort) <(echo "$current_repos" | sort) 2>/dev/null || true)

        if [[ -z "$missing_repos" && -z "$extra_repos" ]]; then
            echo -e "  ${OUTPUT_GREEN}✓ 同期済み${OUTPUT_NC}"
        else
            if [[ -n "$missing_repos" ]]; then
                echo "  追加が必要:"
                while IFS= read -r repo; do
                    echo -e "    ${OUTPUT_GREEN}+ $repo${OUTPUT_NC}"
                done <<< "$missing_repos"
            fi
            if [[ -n "$extra_repos" ]]; then
                echo "  設定ファイルにない:"
                while IFS= read -r repo; do
                    echo -e "    ${OUTPUT_YELLOW}- $repo${OUTPUT_NC}"
                done <<< "$extra_repos"
            fi
        fi
        echo
    done <<< "$secrets"
}

cmd_help() {
    cat << EOF
Codespaces シークレットのリポジトリ紐付け管理

Usage: $SCRIPT_NAME <command> [args]

Commands:
  list              シークレットと紐付けリポジトリを表示
  repos             管理対象リポジトリ一覧を表示
  repos add <repo>  リポジトリを追加 (例: owner/repo)
  repos remove      リポジトリを削除
  repos edit        エディタで設定ファイルを編集
  sync              全シークレットにリポジトリを紐付け
  sync <secret>     特定のシークレットにリポジトリを紐付け
  diff              設定と現在の状態の差分を表示
  init              現在の設定からファイルを初期化
  help              このヘルプを表示

設定ファイル: $CONFIG_DIR/repos.txt

環境変数:
  CODESPACES_SECRETS_CONFIG_DIR  設定ディレクトリのパス (デフォルト: ~/.config/codespaces-secrets)

Examples:
  # 現在の状態を確認
  $SCRIPT_NAME list

  # 現在の設定から初期化
  $SCRIPT_NAME init

  # リポジトリを追加
  $SCRIPT_NAME repos add keito4/my-project
  $SCRIPT_NAME repos add Elu-co-jp/project-a Elu-co-jp/project-b

  # 設定を全シークレットに同期
  $SCRIPT_NAME sync

  # 差分を確認
  $SCRIPT_NAME diff
EOF
}

# ============================================================================
# Main
# ============================================================================

ensure_gh_auth

case "${1:-help}" in
    list)
        cmd_list
        ;;
    repos)
        shift
        cmd_repos "$@"
        ;;
    sync)
        shift
        cmd_sync "$@"
        ;;
    init)
        cmd_init
        ;;
    diff)
        cmd_diff
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        output::fatal "不明なコマンド: $1\n使用方法: $SCRIPT_NAME help"
        ;;
esac
