#!/usr/bin/env bash
# ============================================================================
# Claude Code Setup Script
# ローカル環境/DevContainer両方で動作するプラグインセットアップ
# ============================================================================
# 要件: bash 4.0+ (連想配列を使用)
# macOS: PATH に /opt/homebrew/bin が含まれていること (brew install bash)

set -euo pipefail

# Bash バージョンチェック
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "エラー: このスクリプトは bash 4.0 以降が必要です (現在: ${BASH_VERSION})"
    echo "macOS の場合: brew install bash を実行してください"
    echo "その後、PATH に /opt/homebrew/bin を追加してください"
    exit 1
fi

# Determine script directory and source libraries
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/lib/output.sh
source "$REPO_ROOT/script/lib/output.sh"
# shellcheck source=script/lib/claude_plugins.sh
source "$REPO_ROOT/script/lib/claude_plugins.sh"

# 環境検出とパス設定
CLAUDE_DIR="${HOME}/.claude"
PLUGINS_DIR="${CLAUDE_DIR}/plugins"
PLUGINS_FILE="${PLUGINS_DIR}/plugins.txt"
KNOWN_MARKETPLACES="${PLUGINS_DIR}/known_marketplaces.json"
REPO_PLUGINS_DIR="${REPO_ROOT}/.claude/plugins"
SETTINGS_LOCAL_FILE="${CLAUDE_DIR}/settings.local.json"
DEFAULT_SETTINGS_LOCAL="${REPO_ROOT}/.devcontainer/claude-settings.local.json"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

# 複数の CLAUDE_CONFIG_DIR に共有設定を配るためのキー。
# ここに無いキー（model / theme / tui 等）は各 dir 固有として保持される。
# shellcheck disable=SC2016  # jq に渡すJSONリテラル。$schema はシェル変数ではない
CLAUDE_SHARED_SETTINGS_KEYS='["$schema","hooks","permissions","enabledPlugins","extraKnownMarketplaces","attribution"]'

# settings.local.json のセットアップ
# ホストに settings.local.json がない場合、デフォルトをコピー
setup_settings_local() {
    if [[ ! -f "$SETTINGS_LOCAL_FILE" ]]; then
        log_info "settings.local.json が見つかりません。デフォルト設定をコピーします..."
        if [[ -f "$DEFAULT_SETTINGS_LOCAL" ]]; then
            mkdir -p "$CLAUDE_DIR"
            if cp "$DEFAULT_SETTINGS_LOCAL" "$SETTINGS_LOCAL_FILE" 2>/dev/null; then
                log_success "settings.local.json をセットアップしました"
            else
                log_warn "settings.local.json のコピーに失敗しました"
            fi
        else
            log_warn "デフォルト設定ファイルが見つかりません: ${DEFAULT_SETTINGS_LOCAL}"
        fi
    else
        log_info "settings.local.json は既に存在します"
    fi
}

# 追加の CLAUDE_CONFIG_DIR を列挙する
# Agent Deck の config.toml が group ごとに config_dir を切り替えるため、
# ~/.claude 以外の dir が存在しうる（例: ~/.claude-private, ~/.claude-elu）。
# CLAUDE_EXTRA_CONFIG_DIRS で明示指定も可能（スペース区切り）。
list_extra_config_dirs() {
    if [[ -n "${CLAUDE_EXTRA_CONFIG_DIRS:-}" ]]; then
        local -a explicit_dirs
        read -r -a explicit_dirs <<< "$CLAUDE_EXTRA_CONFIG_DIRS"
        printf '%s\n' "${explicit_dirs[@]}"
        return
    fi
    local dir
    for dir in "${HOME}"/.claude-*; do
        [[ -d "$dir" ]] || continue
        printf '%s\n' "$dir"
    done
}

# 共有設定を追加の CLAUDE_CONFIG_DIR に同期する
#
# なぜ必要か: settings.json は CLAUDE_CONFIG_DIR ごとに独立しており、
# ~/.claude の hooks / permissions / plugins は他の dir では一切読まれない。
# 2026-07-15 時点で ~/.claude-private は hooks 1個・~/.claude-elu は 0個と、
# Quality Gates も permissions も attribution も効かない状態になっていた。
sync_settings_to_extra_config_dirs() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        log_warn "正本の settings.json が見つかりません: ${SETTINGS_FILE}（同期をスキップ）"
        return
    fi
    if ! command -v jq &> /dev/null; then
        log_warn "jq が見つかりません。追加 config dir への設定同期をスキップします"
        return
    fi

    local target_dir target_file tmp_file
    while IFS= read -r target_dir; do
        [[ -n "$target_dir" ]] || continue
        target_file="${target_dir}/settings.json"

        if [[ -e "$target_file" ]] && ! jq -e . "$target_file" > /dev/null 2>&1; then
            log_warn "  ${target_file} が不正なJSONのためスキップします"
            continue
        fi

        tmp_file="$(mktemp)"
        if ! jq --argjson keys "$CLAUDE_SHARED_SETTINGS_KEYS" \
            'with_entries(select(.key as $k | $keys | index($k)))' \
            "$SETTINGS_FILE" > "$tmp_file" 2>/dev/null; then
            log_warn "  共有設定の抽出に失敗しました: ${SETTINGS_FILE}"
            rm -f "$tmp_file"
            continue
        fi

        local merged_file
        merged_file="$(mktemp)"
        if jq -s '(.[0] // {}) + .[1]' \
            <(if [[ -f "$target_file" ]]; then cat "$target_file"; else echo '{}'; fi) \
            "$tmp_file" > "$merged_file" 2>/dev/null && jq -e . "$merged_file" > /dev/null 2>&1; then
            if [[ -f "$target_file" ]] && cmp -s "$target_file" "$merged_file"; then
                log_info "  ${target_dir} は最新です"
            else
                mkdir -p "$target_dir"
                cp "$merged_file" "$target_file"
                log_success "  ${target_dir} に共有設定を同期しました"
            fi
        else
            log_warn "  ${target_file} のマージに失敗しました"
        fi
        rm -f "$tmp_file" "$merged_file"
    done < <(list_extra_config_dirs)
}

main() {
    log_info "Claude Code セットアップを開始します..."
    log_info "環境: HOME=${HOME}"

    # CLAUDE_ENV_FILE が設定されている場合、環境変数ファイルを読み込む
    if [[ -n "${CLAUDE_ENV_FILE:-}" ]] && [[ -f "$CLAUDE_ENV_FILE" ]]; then
        log_info "環境変数ファイルを読み込みます: ${CLAUDE_ENV_FILE}"
        # shellcheck source=/dev/null
        source "$CLAUDE_ENV_FILE"
    fi

    # 一時ディレクトリを作成（クロスデバイスリンクエラー対策）
    mkdir -p "${CLAUDE_DIR}/tmp"
    export TMPDIR="${CLAUDE_DIR}/tmp"

    # settings.local.json のセットアップ
    setup_settings_local

    # 追加の CLAUDE_CONFIG_DIR（~/.claude-private 等）へ共有設定を同期
    log_info "追加の CLAUDE_CONFIG_DIR に共有設定を同期します..."
    sync_settings_to_extra_config_dirs

    # Claude CLI の存在確認
    if ! command -v claude &> /dev/null; then
        log_warn "Claude CLI が見つかりません。プラグインのインストールはスキップされます。"
        exit 0
    fi

    # リポジトリからコマンド・エージェント・フックを同期
    plugins::sync_repo_content "$REPO_ROOT" "$CLAUDE_DIR"

    # 重要なコマンドの確認
    verify_important_commands

    # プラグイン設定ファイルのコピー
    plugins::copy_config_files "$REPO_PLUGINS_DIR" "$PLUGINS_DIR"

    # plugins.txtの存在確認
    if [[ ! -f "$PLUGINS_FILE" ]]; then
        log_warn "plugins.txt が見つかりません: ${PLUGINS_FILE}"
        exit 0
    fi

    # マーケットプレイスの自動検出と追加
    plugins::detect_and_add_marketplaces "$PLUGINS_FILE" "$KNOWN_MARKETPLACES"

    # プラグインのインストール
    plugins::install_from_manifest "$PLUGINS_FILE"

    # hookifyパッチの適用
    plugins::apply_hookify_patch "$CLAUDE_DIR"

    log_success "Claude Code セットアップが完了しました！"
}

# 重要なコマンドの確認と配置
verify_important_commands() {
    local repo_commands_dir="${REPO_ROOT}/.claude/commands"
    local target_commands_dir="${CLAUDE_DIR}/commands"

    local important_commands=(
        "config-base-sync-update.md"
        "config-base-sync-check.md"
    )

    for important_cmd in "${important_commands[@]}"; do
        if [[ -f "${repo_commands_dir}/${important_cmd}" ]]; then
            if [[ ! -f "${target_commands_dir}/${important_cmd}" ]]; then
                log_warn "  重要なコマンドが配置されていません: ${important_cmd}"
                mkdir -p "$target_commands_dir"
                if cp "${repo_commands_dir}/${important_cmd}" "${target_commands_dir}/${important_cmd}" 2>/dev/null; then
                    log_success "  ${important_cmd} を配置しました"
                else
                    log_warn "  ${important_cmd} の配置に失敗しました"
                fi
            else
                log_info "  ${important_cmd} が配置されています"
            fi
        fi
    done
}

main "$@"
