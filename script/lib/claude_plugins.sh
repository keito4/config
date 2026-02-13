#!/usr/bin/env bash
# ============================================================================
# Claude Code Plugin Management Library
# プラグイン管理の共通機能を提供
# ============================================================================

set -euo pipefail

# 定数定義
# Fallback marketplace list (synced with known_marketplaces.json.template)
# Format: "name:repo" for GitHub repos, "name:url:https://..." for full URLs
readonly PLUGINS_KNOWN_MARKETPLACES_FALLBACK=(
    "agent-browser:vercel-labs/agent-browser"
    "anthropic-agent-skills:url:https://github.com/anthropics/skills.git"
    "claude-code-plugins:anthropics/claude-code"
    "claude-code-templates:url:https://github.com/davila7/claude-code-templates.git"
    "claude-code-workflows:wshobson/agents"
    "claude-plugins-official:anthropics/claude-plugins-official"
    "intellectronica-skills:intellectronica/agent-skills"
    "playwright-skill:lackeyjb/playwright-skill"
    "supabase-agent-skills:supabase/agent-skills"
)

# コマンド・エージェント・フックの同期
# 使用法: plugins::sync_repo_content <repo_dir> <claude_dir>
plugins::sync_repo_content() {
    local repo_root="${1:?Repository root required}"
    local claude_dir="${2:?Claude directory required}"

    local repo_commands_dir="${repo_root}/.claude/commands"
    local repo_agents_dir="${repo_root}/.claude/agents"
    local repo_hooks_dir="${repo_root}/.claude/hooks"

    log_info "リポジトリからコマンド・エージェント・フックを同期中..."

    # コマンドの同期
    plugins::_sync_directory "$repo_commands_dir" "${claude_dir}/commands" "コマンド" "*.md"

    # エージェントの同期
    plugins::_sync_directory "$repo_agents_dir" "${claude_dir}/agents" "エージェント"

    # フックの同期
    plugins::_sync_directory "$repo_hooks_dir" "${claude_dir}/hooks" "フック"
}

# ディレクトリの同期（内部関数）
plugins::_sync_directory() {
    local source_dir="$1"
    local target_dir="$2"
    local name="$3"
    local pattern="${4:-}"

    if [[ ! -d "$source_dir" ]]; then
        log_info "リポジトリに${name}ディレクトリが見つかりません"
        return 0
    fi

    if [[ -z "$(ls -A "$source_dir" 2>/dev/null)" ]]; then
        log_info "リポジトリに${name}が見つかりません"
        return 0
    fi

    mkdir -p "$target_dir"

    if [[ -n "$pattern" ]]; then
        # パターン指定あり：ファイルを個別にコピー
        local copied_count=0
        while IFS= read -r -d '' file; do
            local filename
            filename=$(basename "$file")
            if cp "$file" "${target_dir}/${filename}" 2>/dev/null; then
                copied_count=$((copied_count + 1))
            else
                log_warn "  ${name}のコピーに失敗: ${filename}"
            fi
        done < <(find "$source_dir" -maxdepth 1 -type f -name "$pattern" -print0 2>/dev/null)

        if [[ $copied_count -gt 0 ]]; then
            log_success "${name}を同期しました: ${copied_count} ファイル"
        fi
    else
        # パターン指定なし：ディレクトリ全体をコピー
        cp -r "${source_dir}"/* "${target_dir}/" 2>/dev/null || true
        local count
        count=$(find "$target_dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
        log_success "${name}を同期しました: ${count} ファイル"
    fi
}

# プラグイン設定ファイルのコピー
# 使用法: plugins::copy_config_files <repo_plugins_dir> <plugins_dir>
plugins::copy_config_files() {
    local repo_plugins_dir="${1:?Repository plugins directory required}"
    local plugins_dir="${2:?Plugins directory required}"

    log_info "リポジトリからプラグイン設定をコピー中..."
    mkdir -p "$plugins_dir"

    local plugins_file="${plugins_dir}/plugins.txt"
    local template="${plugins_dir}/known_marketplaces.json.template"
    local known_marketplaces="${plugins_dir}/known_marketplaces.json"

    if [[ -f "${repo_plugins_dir}/plugins.txt" ]]; then
        cp "${repo_plugins_dir}/plugins.txt" "$plugins_file"
        log_success "plugins.txt をコピーしました"
    else
        log_warn "リポジトリにplugins.txtが見つかりません"
    fi

    if [[ -f "${repo_plugins_dir}/known_marketplaces.json.template" ]]; then
        cp "${repo_plugins_dir}/known_marketplaces.json.template" "$template"
        log_success "known_marketplaces.json.template をコピーしました"

        # テンプレートから known_marketplaces.json を生成
        log_info "テンプレートから known_marketplaces.json を生成中..."
        sed "s|{{HOME}}|${HOME}|g" "$template" > "$known_marketplaces"
        log_success "known_marketplaces.json を生成しました"
    fi
}

# マーケットプレイスの自動検出と追加
# 使用法: plugins::detect_and_add_marketplaces <plugins_file> <known_marketplaces_file>
plugins::detect_and_add_marketplaces() {
    local plugins_file="${1:?Plugins file required}"
    local known_marketplaces="${2:-}"

    log_info "マーケットプレイスを自動検出して初期化中..."

    if [[ ! -f "$plugins_file" ]]; then
        log_warn "plugins.txt が見つかりません: ${plugins_file}"
        return 1
    fi

    # plugins.txtから必要なマーケットプレイスを抽出
    declare -A marketplaces_needed
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 空行とコメント行をスキップ
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # マーケットプレイス名を抽出（@以降の部分）
        if [[ "$line" =~ @([^[:space:]]+) ]]; then
            marketplaces_needed["${BASH_REMATCH[1]}"]=1
        fi
    done < "$plugins_file"

    # マーケットプレイスを追加
    for marketplace in "${!marketplaces_needed[@]}"; do
        plugins::_add_marketplace "$marketplace" "$known_marketplaces"
    done
}

# マーケットプレイスを追加（内部関数）
plugins::_add_marketplace() {
    local marketplace="$1"
    local known_marketplaces="${2:-}"

    # known_marketplaces.jsonからURLを取得
    if [[ -n "$known_marketplaces" ]] && [[ -f "$known_marketplaces" ]] && command -v jq &> /dev/null; then
        local repo url
        repo=$(jq -r ".\"$marketplace\".source.repo // empty" "$known_marketplaces" 2>/dev/null)
        url=$(jq -r ".\"$marketplace\".source.url // empty" "$known_marketplaces" 2>/dev/null)

        if [[ -n "$repo" ]]; then
            claude plugin marketplace add "https://github.com/${repo}.git" 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
            return 0
        elif [[ -n "$url" ]]; then
            claude plugin marketplace add "$url" 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
            return 0
        fi
    fi

    # フォールバック: 固定リストから取得
    # Format: "name:repo" for GitHub repos, "name:url:https://..." for full URLs
    for entry in "${PLUGINS_KNOWN_MARKETPLACES_FALLBACK[@]}"; do
        local name="${entry%%:*}"
        local value="${entry#*:}"

        if [[ "$name" == "$marketplace" ]]; then
            if [[ "$value" == url:* ]]; then
                # URL形式: "name:url:https://..."
                local full_url="${value#url:}"
                claude plugin marketplace add "$full_url" 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
            else
                # GitHub repo形式: "name:owner/repo"
                claude plugin marketplace add "https://github.com/${value}.git" 2>/dev/null || log_info "  ${marketplace}: 既に追加済み"
            fi
            return 0
        fi
    done

    log_warn "  ${marketplace}: 未知のマーケットプレイス"
}

# プラグインのインストール
# 使用法: plugins::install_from_manifest <plugins_file>
plugins::install_from_manifest() {
    local plugins_file="${1:?Plugins file required}"

    log_info "プラグインをユーザースコープでインストール中..."

    if [[ ! -f "$plugins_file" ]]; then
        log_warn "plugins.txt が見つかりません: ${plugins_file}"
        return 1
    fi

    local installed=0 failed=0 skipped=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # 空行とコメント行をスキップ
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # 前後の空白を除去
        local plugin
        plugin=$(echo "$line" | xargs)
        [[ -z "$plugin" ]] && continue

        log_info "  インストール中: ${plugin}"

        local output
        if output=$(claude plugin install "$plugin" 2>&1); then
            log_success "  完了: ${plugin}"
            installed=$((installed + 1))
        else
            if echo "$output" | grep -q "already installed\|already exists"; then
                log_info "  スキップ: ${plugin} (既にインストール済み)"
                skipped=$((skipped + 1))
            else
                log_warn "  失敗: ${plugin}"
                echo "    エラー: $output" | head -3
                failed=$((failed + 1))
            fi
        fi
    done < "$plugins_file"

    log_info "プラグイン: ${installed} インストール完了、${skipped} スキップ、${failed} 失敗"
}

# hookifyプラグインのパッチ適用
# 使用法: plugins::apply_hookify_patch <claude_dir>
plugins::apply_hookify_patch() {
    local claude_dir="${1:?Claude directory required}"

    log_info "hookifyプラグインのインポートパッチを適用中..."

    local hookify_paths=(
        "${claude_dir}/plugins/marketplaces/claude-code-plugins/plugins/hookify"
        "${claude_dir}/plugins/marketplaces/claude-plugins-official/plugins/hookify"
    )

    # cacheディレクトリ内のhookifyプラグインも検索
    if [[ -d "${claude_dir}/plugins/cache" ]]; then
        while IFS= read -r -d '' cache_dir; do
            if [[ -d "$cache_dir" ]] && [[ "$cache_dir" == *"/hookify" ]]; then
                hookify_paths+=("$cache_dir")
            fi
        done < <(find "${claude_dir}/plugins/cache" -type d -name "hookify" -print0 2>/dev/null)
    fi

    local hookify_found=0

    for hookify_dir in "${hookify_paths[@]}"; do
        if [[ -d "$hookify_dir" ]]; then
            hookify_found=1
            log_info "  パッチ適用先: ${hookify_dir}"

            plugins::_patch_hookify_imports "$hookify_dir"
            plugins::_patch_hookify_shebangs "$hookify_dir"
            plugins::_ensure_hookify_init "$hookify_dir"
        fi
    done

    if [[ $hookify_found -eq 0 ]]; then
        log_info "hookifyプラグインが見つかりません。パッチはスキップします。"
    fi
}

# hookifyのインポートをパッチ（内部関数）
plugins::_patch_hookify_imports() {
    local hookify_dir="$1"

    find "$hookify_dir" -name "*.py" -type f -exec perl -i -pe \
        's/from hookify\.core/from core/g; s/from hookify\.utils/from utils/g; s/from hookify\.matchers/from matchers/g;' \
        {} \; 2>/dev/null
}

# hookifyのshebangをパッチ（内部関数）
plugins::_patch_hookify_shebangs() {
    local hookify_dir="$1"

    # hooks/ディレクトリ内のPythonスクリプト
    if [[ -d "${hookify_dir}/hooks" ]]; then
        for py_file in "${hookify_dir}/hooks"/*.py; do
            [[ -f "$py_file" ]] || continue
            plugins::_fix_shebang "$py_file"
        done
        log_success "  hookスクリプトのshebangを修正しました"
    fi

    # プラグインルートディレクトリ内のPythonファイル
    for py_file in "${hookify_dir}"/*.py; do
        [[ -f "$py_file" ]] || continue
        plugins::_fix_shebang "$py_file"
    done
}

# shebangを修正（内部関数）
plugins::_fix_shebang() {
    local py_file="$1"

    if head -n1 "$py_file" | grep -q "^#!"; then
        perl -i -pe 's|^#!.*python.*|#!/usr/bin/env python3|' "$py_file"
    else
        local tmp_file
        tmp_file=$(mktemp)
        echo '#!/usr/bin/env python3' > "$tmp_file"
        cat "$py_file" >> "$tmp_file"
        mv "$tmp_file" "$py_file"
    fi
    chmod +x "$py_file"
}

# hookifyの__init__.pyを確保（内部関数）
plugins::_ensure_hookify_init() {
    local hookify_dir="$1"

    if [[ ! -f "${hookify_dir}/__init__.py" ]]; then
        cat > "${hookify_dir}/__init__.py" <<'INIT_EOF'
"""Hookify plugin package.

This package provides hook-based automation for Claude Code.
"""

__version__ = "0.1.0"
INIT_EOF
        log_success "  __init__.pyを作成しました"
    fi
}
