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

# 個人/組織情報を含むスキルの正本を置く非公開リポジトリ。
# 端末ごとにパスが変わりうるため上書き可能にする。
PRIVATE_CONFIG_DIR="${PRIVATE_CONFIG_DIR:-${HOME}/develop/github.com/keito4/private-config}"

# スキルの symlink 先は、作業ツリーではなく origin/main 追従の専用チェックアウト
# （<repo>-deploy-main worktree）に統一する。作業ツリーを直接指すと、
#   - ブランチ切替や未コミット変更がそのまま全セッションのスキル挙動になる
#   - 逆に main へマージした修正が、作業ツリーが別ブランチにいる限り配備されない
# という2方向の事故が起きるため（2026-09-05 方針A決定）。
# 編集中のスキルを即試したいときだけ、これらを作業ツリーのパスへ上書きして実行する。
# `%-deploy-main` の除去は、deploy-main チェックアウト内からこのスクリプトを
# 実行した場合に <repo>-deploy-main-deploy-main という入れ子 worktree を作らないため。
CONFIG_DEPLOY_DIR="${CONFIG_DEPLOY_DIR:-${REPO_ROOT%-deploy-main}-deploy-main}"
PRIVATE_CONFIG_DEPLOY_DIR="${PRIVATE_CONFIG_DEPLOY_DIR:-${PRIVATE_CONFIG_DIR%-deploy-main}-deploy-main}"

# 複数の CLAUDE_CONFIG_DIR に共有設定を配るためのキー。
# ここに無いキー（model / theme / tui 等）は各 dir 固有として保持される。
# shellcheck disable=SC2016  # jq に渡すJSONリテラル。$schema はシェル変数ではない
CLAUDE_SHARED_SETTINGS_KEYS='["$schema","hooks","permissions","enabledPlugins","extraKnownMarketplaces","attribution"]'

# 追加の CLAUDE_CONFIG_DIR に ~/.claude からリンクするコンテンツ。
# hooks は settings.json 側がプロジェクト相対 (.claude/hooks/...) で解決するため対象外。
CLAUDE_LINKED_CONTENT_DIRS=(commands agents skills)

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

# ~/.claude/settings.json をホスト所有の実体ファイルとして用意する。
#
# なぜ symlink にしないか: このファイルには Claude Code がプラグイン導入状態を、
# agent-deck が hooks（agent-deck hook-handler）を書き戻す。リポジトリの追跡ファイルへ
# symlink すると、その端末固有の状態がコミット対象になり、ADR 0019 の downstream 同期や
# このリポジトリ自身の CI（GitHub Actions 上の Claude Code）にも流れる。CI には
# agent-deck が無いため、SessionStart hook が毎回失敗する。
#
# リポジトリのベースラインは初回の種として配る。既存ファイルには
# permissions.allow だけを追加マージし、それ以外の端末固有設定は保持する。
merge_baseline_permissions_allow() {
    local baseline="$1"

    if ! command -v jq &> /dev/null; then
        log_warn "jq が見つかりません。${SETTINGS_FILE} への permissions.allow 同期をスキップします"
        return
    fi

    if ! jq -e '
        type == "object"
        and (.permissions | type == "object")
        and (.permissions.allow | type == "array")
        and all(.permissions.allow[]; type == "string")
    ' "$baseline" > /dev/null 2>&1; then
        log_warn "ベースラインの permissions.allow が不正なため同期をスキップします: ${baseline}"
        return
    fi

    if ! jq -e '
        if type != "object" then false
        elif (has("permissions") | not) then true
        elif (.permissions | type) != "object" then false
        elif (.permissions | has("allow") | not) then true
        else (.permissions.allow | type == "array")
            and all(.permissions.allow[]; type == "string")
        end
    ' "$SETTINGS_FILE" > /dev/null 2>&1; then
        log_warn "${SETTINGS_FILE} が不正なJSONまたは permissions.allow の形式が不正なため同期をスキップします"
        return
    fi

    local merged_file
    merged_file="$(mktemp)"
    if ! jq -s '
        .[0] as $current
        | .[1] as $baseline
        | (reduce (($current.permissions.allow // []) + $baseline.permissions.allow)[] as $entry
            ([]; if index($entry) == null then . + [$entry] else . end)) as $allow
        | $current
        | setpath(["permissions", "allow"]; $allow)
    ' "$SETTINGS_FILE" "$baseline" > "$merged_file" 2>/dev/null; then
        log_warn "${SETTINGS_FILE} の permissions.allow マージに失敗しました"
        rm -f "$merged_file"
        return
    fi

    if cmp -s "$SETTINGS_FILE" "$merged_file"; then
        log_info "${SETTINGS_FILE} の permissions.allow は最新です"
    else
        cp "$merged_file" "$SETTINGS_FILE"
        log_success "${SETTINGS_FILE} の permissions.allow をベースラインから同期しました"
    fi
    rm -f "$merged_file"
}

seed_user_settings() {
    local baseline="${REPO_ROOT}/.claude/settings.json"

    if [[ -L "$SETTINGS_FILE" ]]; then
        # 旧構成（追跡ファイルへの symlink）からの移行。リンク先の内容を保ったまま実体化する。
        local tmp
        tmp="$(mktemp)"
        cp "$SETTINGS_FILE" "$tmp"
        rm -f "$SETTINGS_FILE"
        mv "$tmp" "$SETTINGS_FILE"
        chmod 644 "$SETTINGS_FILE"
        log_success "${SETTINGS_FILE} を symlink から実体に置き換えました"
    fi

    if [[ ! -f "$baseline" ]]; then
        log_warn "ベースラインの settings.json が見つかりません: ${baseline}"
        return
    fi

    if [[ ! -e "$SETTINGS_FILE" ]]; then
        mkdir -p "$CLAUDE_DIR"
        cp "$baseline" "$SETTINGS_FILE"
        log_success "${SETTINGS_FILE} をリポジトリのベースラインから作成しました"
        return
    fi

    log_info "${SETTINGS_FILE} は既に存在します（端末固有設定を保持します）"
    merge_baseline_permissions_allow "$baseline"
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
        # 初期化済みの実 config_dir のみ対象にする（settings.json か .claude.json を持つ）。
        # hook 置き場等（例: ~/.claude-worklog）に無用な settings.json を生成しないため。
        [[ -f "$dir/settings.json" || -f "$dir/.claude.json" ]] || continue
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

# commands / agents / skills を追加の CLAUDE_CONFIG_DIR にシンボリックリンクする
#
# なぜコピーではなくリンクか: これらは dir ごとに差分を持つ理由が現状なく、
# コピーだと make claude-setup を忘れた端末で静かにドリフトする。
# リンクなら ~/.claude に置いた時点で全 dir に反映され、ドリフトが原理的に起きない。
#
# なぜリポジトリからではなく ~/.claude から配るか: keito4/config は public のため
# 個人情報を含むコマンド（例: 個人 Notion の ID を持つ /session-close）は追跡できない。
# 正本を ~/.claude に置く方針は settings.json の同期（#977）と同じ。
link_content_to_extra_config_dirs() {
    local target_dir name source_path target_path
    while IFS= read -r target_dir; do
        [[ -n "$target_dir" ]] || continue

        for name in "${CLAUDE_LINKED_CONTENT_DIRS[@]}"; do
            source_path="${CLAUDE_DIR}/${name}"
            target_path="${target_dir}/${name}"

            if [[ ! -e "$source_path" ]]; then
                log_info "  ${source_path} が無いため ${name} のリンクをスキップします"
                continue
            fi

            if [[ -L "$target_path" ]]; then
                if [[ "$(readlink "$target_path")" == "$source_path" ]]; then
                    log_info "  ${target_path} は最新です"
                    continue
                fi
                rm -f "$target_path"
            elif [[ -e "$target_path" ]]; then
                # 実体があるものを消すと中身を失う。手動退避を促して触らない。
                log_warn "  ${target_path} は実体のためスキップします（退避してから再実行してください）"
                continue
            fi

            mkdir -p "$target_dir"
            if ln -s "$source_path" "$target_path"; then
                log_success "  ${target_path} -> ${source_path} をリンクしました"
            else
                log_warn "  ${target_path} のリンクに失敗しました"
            fi
        done
    done < <(list_extra_config_dirs)
}

# リポジトリ / private-config のスキルを ~/.claude/skills に展開する。
#
# なぜ必要か:
#   1. Claude Code はスキルを <name>/SKILL.md ディレクトリ形式でしか読まない。
#      commands / agents のようにディレクトリごとリンクすると、npx skills add で
#      入るホスト固有のスキルと同居できないため、スキル単位でリンクする。
#   2. 組織メンバーのメール・Slack ID・内部 Notion ID を含むスキル（例 oykot-tasks）は
#      public な keito4/config には置けず、keito4/private-config が正本になる。
#      新端末では private-config のスキルが materialize されず呼べなかった。
#
# なぜ symlink か: 正本にドリフトなく追随するため（settings 同期 #977 と同方針）。
# 正本が明確なので、既存の実体コピーや古いリンクは置き換える（追加 config-dir の
# ケースと異なり、ここではドリフト除去を優先する）。
#
# 正本側には 1ファイルのスキル（<name>.md）と、スクリプト等を伴うスキル
# （<name>/SKILL.md + <name>/scripts/...）の2形式がある。後者は SKILL.md だけ
# リンクすると補助ファイルが見えないため、ディレクトリごとリンクする。

# スキルのシンボリックリンクを作成/更新する共通ヘルパー。
# link_skill_file / link_skill_dir はどちらも「target が既に src を指す
# symlink なら何もしない → 無ければ張り替える」という同じ手順のため、
# 対象パスの違い（ファイル1階層 or ディレクトリ）だけを呼び出し側に残して集約する。
link_skill_symlink() {
    local src="$1" target="$2" name="$3"

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$src" ]]; then
        log_info "  スキル ${name} は最新です"
        return
    fi

    mkdir -p "$(dirname "$target")"
    rm -rf "$target"
    if ln -s "$src" "$target"; then
        log_success "  スキル ${name} -> ${src} をリンクしました"
    else
        log_warn "  スキル ${name} のリンクに失敗しました"
    fi
}

# 単一ファイルのスキル: <name>.md -> ~/.claude/skills/<name>/SKILL.md
link_skill_file() {
    local md="$1" skills_dir="$2"
    local name
    name="$(basename "$md" .md)"
    link_skill_symlink "$md" "${skills_dir}/${name}/SKILL.md" "$name"
}

# 補助ファイルを伴うスキル: <name>/ -> ~/.claude/skills/<name>
link_skill_dir() {
    local src="$1" skills_dir="$2"
    local name target
    name="$(basename "$src")"
    target="${skills_dir}/${name}"

    if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
        log_warn "  スキル ${name} の実体コピーを private-config へのリンクに置き換えます"
    fi

    link_skill_symlink "$src" "$target" "$name"
}

# <repo>-deploy-main（origin/main 追従の専用 worktree）を用意・更新する。
# - 無ければ worktree として作成し、あれば origin/main へ detach で追従させる
# - fetch 失敗（オフライン等）は警告して手元の状態のまま続行（古くても予測可能を優先）
# - deploy 側に手元変更があれば上書きせず警告する（deploy 用チェックアウトは編集禁止）
# 戻り値: deploy チェックアウトが使える場合 0、使えない場合 1。
ensure_deploy_main_checkout() {
    local repo_dir="$1" deploy_dir="$2"
    # refspec を明示して remote-tracking ref (origin/main) を確実に更新する
    # （既定 refspec に依存した opportunistic update に頼らない）。
    local fetch_refspec="+refs/heads/main:refs/remotes/origin/main"

    if [[ ! -d "$deploy_dir" ]]; then
        if ! git -C "$repo_dir" rev-parse --git-dir &>/dev/null; then
            log_warn "  ${repo_dir} は git リポジトリではないため deploy-main を用意できません"
            return 1
        fi
        if ! git -C "$repo_dir" fetch --quiet origin "$fetch_refspec" 2>/dev/null; then
            log_warn "  ${repo_dir} の fetch に失敗しました（オフライン?）"
        fi
        if git -C "$repo_dir" worktree add --detach "$deploy_dir" origin/main &>/dev/null; then
            log_success "  deploy-main チェックアウトを作成しました: ${deploy_dir}"
            return 0
        fi
        log_warn "  deploy-main チェックアウトの作成に失敗しました: ${deploy_dir}"
        return 1
    fi

    # 既存ディレクトリが git 作業ツリーでない（壊れた/無関係のディレクトリ）場合は
    # 参照元として採用せず、呼び出し側のフォールバックに回す。
    if ! git -C "$deploy_dir" rev-parse --is-inside-work-tree &>/dev/null; then
        log_warn "  ${deploy_dir} は git 作業ツリーではありません。deploy-main として使えないためフォールバックします"
        return 1
    fi

    # 環境変数で deploy 先を作業ツリー自身に向けた場合（相対パス・symlink 経由の
    # 別表記を含む）は、作業ツリーを勝手に detach しないよう追従処理をしない。
    # 同一性はパス文字列ではなく git の toplevel で判定する。
    local repo_top deploy_top
    repo_top="$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null || true)"
    deploy_top="$(git -C "$deploy_dir" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -z "$repo_top" ]] || [[ "$deploy_top" == "$repo_top" ]]; then
        log_info "  deploy 先が作業ツリーと同一のため origin/main への追従をスキップします"
        return 0
    fi

    # 無関係なリポジトリのチェックアウトを誤って配備しないよう origin を突合する。
    # （同一リポジトリなら worktree でも別 clone でも許容する）
    local repo_origin deploy_origin
    repo_origin="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
    deploy_origin="$(git -C "$deploy_dir" remote get-url origin 2>/dev/null || true)"
    if [[ -z "$deploy_origin" ]] || [[ "$deploy_origin" != "$repo_origin" ]]; then
        log_warn "  ${deploy_dir} の origin が ${repo_dir} と一致しません。誤配備防止のためフォールバックします"
        return 1
    fi

    if [[ -n "$(git -C "$deploy_dir" status --porcelain 2>/dev/null)" ]]; then
        log_warn "  ${deploy_dir} に手元変更があります。origin/main への追従をスキップします（deploy 用チェックアウトは編集しないでください）"
        return 0
    fi

    # worktree（repo と ref 共有）でも別 clone でも成立するよう、deploy 側で fetch する。
    if ! git -C "$deploy_dir" fetch --quiet origin "$fetch_refspec" 2>/dev/null; then
        log_warn "  ${deploy_dir} の fetch に失敗しました（オフライン?）。deploy-main は手元の状態のまま使います"
    fi
    if git -C "$deploy_dir" checkout --quiet --detach origin/main 2>/dev/null; then
        log_info "  deploy-main を origin/main ($(git -C "$deploy_dir" rev-parse --short HEAD)) に更新しました"
    else
        log_warn "  ${deploy_dir} を origin/main へ更新できませんでした。現在の状態のまま使います"
    fi
    return 0
}

# スキルの参照元を決めて SKILLS_SOURCE_DIR に入れる。
# deploy-main が使えればそれを、用意できない環境では作業ツリーへフォールバックする。
# （log_* は stdout に出るため、コマンド置換ではなくグローバル変数で返す。）
SKILLS_SOURCE_DIR=""
resolve_skills_source() {
    local repo_dir="$1" deploy_dir="$2"
    if ensure_deploy_main_checkout "$repo_dir" "$deploy_dir"; then
        SKILLS_SOURCE_DIR="$deploy_dir"
    else
        log_warn "  フォールバック: 作業ツリー ${repo_dir} からスキルをリンクします（ブランチ状態がそのまま反映される点に注意）"
        SKILLS_SOURCE_DIR="$repo_dir"
    fi
}

link_skills_from_dir() {
    local src_dir="$1"
    if [[ ! -d "$src_dir" ]]; then
        log_info "スキルの正本が見つからないためスキップします (${src_dir})"
        return
    fi

    local skills_dir="${CLAUDE_DIR}/skills"
    local entry
    shopt -s nullglob
    for entry in "$src_dir"/*; do
        # symlink のエントリは npx skills add でホストに入れた実体への参照であり、
        # リポジトリが正本ではないため配布対象にしない。
        [[ -L "$entry" ]] && continue

        if [[ -f "$entry" ]] && [[ "$entry" == *.md ]] && [[ "$(basename "$entry")" != "README.md" ]]; then
            link_skill_file "$entry" "$skills_dir"
        elif [[ -d "$entry" ]] && [[ -f "${entry}/SKILL.md" ]]; then
            link_skill_dir "$entry" "$skills_dir"
        fi
    done
    shopt -u nullglob
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

    # ~/.claude/settings.json をホスト所有の実体として用意（extra dir への同期元になる）
    seed_user_settings

    # 追加の CLAUDE_CONFIG_DIR（~/.claude-private 等）へ共有設定を同期
    log_info "追加の CLAUDE_CONFIG_DIR に共有設定を同期します..."
    sync_settings_to_extra_config_dirs

    # スキルを ~/.claude/skills に展開（extra dir へのリンク前に実行）。
    # 参照元は origin/main 追従の deploy-main チェックアウトに統一する（方針A）。
    # 名前が衝突した場合は private-config を勝たせるため、リポジトリを先に処理する。
    log_info "スキル配備用の deploy-main チェックアウトを確認します..."
    resolve_skills_source "$REPO_ROOT" "$CONFIG_DEPLOY_DIR"
    local repo_skills_src="$SKILLS_SOURCE_DIR"
    resolve_skills_source "$PRIVATE_CONFIG_DIR" "$PRIVATE_CONFIG_DEPLOY_DIR"
    local private_skills_src="$SKILLS_SOURCE_DIR"

    log_info "リポジトリのスキルを ~/.claude/skills に展開します..."
    link_skills_from_dir "${repo_skills_src}/.claude/skills"
    log_info "private-config の個人スキルを ~/.claude/skills に展開します..."
    link_skills_from_dir "${private_skills_src}/.claude/skills"

    # commands / agents / skills を追加の CLAUDE_CONFIG_DIR にリンク
    # claude CLI の有無に依存しないため、CLI チェックより前に実行する
    log_info "追加の CLAUDE_CONFIG_DIR に commands/agents/skills をリンクします..."
    link_content_to_extra_config_dirs

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
