#!/usr/bin/env bash
# ============================================================================
# Claude Code Version Update Script
# Claude Code の最新バージョンに更新します（ネイティブインストーラー使用）
# Dockerfile のバージョンも同時に更新します
# ============================================================================

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKERFILE="${PROJECT_ROOT}/.devcontainer/Dockerfile"

# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"

log_info "Claude Code バージョン更新を開始します..."

# npm registry から最新バージョンを取得
get_latest_version() {
    curl -s "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4
}

# Dockerfile から現在のバージョンを取得（claude.ai/install.sh の行から）
get_dockerfile_version() {
    grep "claude.ai/install.sh" "${DOCKERFILE}" | grep -o 'bash -s [0-9.]*' | cut -d' ' -f3
}

# Dockerfile のバージョンを更新
update_dockerfile_version() {
    local new_version="$1"
    local current_version
    current_version=$(get_dockerfile_version)

    if [[ "${current_version}" == "${new_version}" ]]; then
        log_info "Dockerfile は既に最新バージョンです (${current_version})"
        return 1
    fi

    # claude.ai/install.sh を含む行のみバージョンを更新
    # NOTE: 引数なしの `sed -i` は GNU sed 専用。BSD sed (macOS) では直後の
    #       引数をバックアップ拡張子として解釈するため、式がファイル名として
    #       扱われて失敗する。一時ファイルへ書き出してから元ファイルへ流し込む
    #       ことで、GNU / BSD どちらの sed でも動作させる。
    #       `cat >` で書き戻すのは、元ファイルの権限と inode を保つため。
    local tmp_dockerfile
    tmp_dockerfile="$(mktemp)"
    sed "/claude.ai\/install.sh/s|bash -s ${current_version}|bash -s ${new_version}|" \
        "${DOCKERFILE}" >"${tmp_dockerfile}"
    cat "${tmp_dockerfile}" >"${DOCKERFILE}"
    rm -f "${tmp_dockerfile}"
    log_success "Dockerfile を ${current_version} → ${new_version} に更新しました"
    return 0
}

# 最新バージョンを取得
latest_version=$(get_latest_version)
if [[ -z "${latest_version}" ]]; then
    error "最新バージョンの取得に失敗しました"
    exit 1
fi
log_info "最新バージョン: ${latest_version}"

# Dockerfile の現在のバージョンを取得
dockerfile_version=$(get_dockerfile_version)
log_info "Dockerfile のバージョン: ${dockerfile_version}"

# claudeコマンドの存在確認
if command -v claude &> /dev/null; then
    current_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
    log_info "インストール済みバージョン: ${current_version}"

    # 更新を実行
    log_info "Claude Code を更新中..."
    if claude update; then
        new_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
        if [[ "$current_version" == "$new_version" ]]; then
            log_success "Claude Code は既に最新バージョンです (${current_version})"
        else
            log_success "Claude Code を ${current_version} → ${new_version} に更新しました"
        fi
    else
        log_warn "claude update に失敗しました。再インストールを試みます..."
        if curl -fsSL https://claude.ai/install.sh | bash -s "${latest_version}"; then
            new_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
            log_success "Claude Code を再インストールしました (${new_version})"
        else
            error "Claude Code の更新に失敗しました"
            exit 1
        fi
    fi
else
    log_warn "Claude CLI が見つかりません。Dockerfile のみ更新します。"
fi

# Dockerfile のバージョンを更新
if update_dockerfile_version "${latest_version}"; then
    echo ""
    log_info "Dockerfile の変更内容:"
    git diff "${DOCKERFILE}" 2>/dev/null || true
fi

# リリースノートのURLを表示
log_info "リリースノート: https://github.com/anthropics/claude-code/releases"

log_success "更新完了！"
