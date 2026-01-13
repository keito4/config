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
