#!/usr/bin/env bash
# MCP 設定セットアップスクリプト
# 環境変数を使用して .mcp.json を生成します

set -euo pipefail

# ディレクトリパス
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MCP_TEMPLATE="$REPO_ROOT/.mcp.json.template"
MCP_OUTPUT="$REPO_ROOT/.mcp.json"
MCP_ENV="$REPO_ROOT/credentials/mcp.env"

# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"

# envsubst の利用可否をチェック
check_envsubst() {
    if ! command -v envsubst >/dev/null 2>&1; then
        print_error "envsubst コマンドが見つかりません"
        print_info ""
        print_info "インストール方法:"
        print_info "  macOS: brew install gettext && brew link --force gettext"
        print_info "  Ubuntu/Debian: apt-get install gettext-base"
        return 1
    fi
    return 0
}

# メイン処理
main() {
    print_info "MCP 設定セットアップを開始します"
    print_info ""

    # envsubst の確認
    if ! check_envsubst; then
        exit 1
    fi

    # テンプレートファイルの確認
    if [[ ! -f "$MCP_TEMPLATE" ]]; then
        print_error "テンプレートファイルが見つかりません: $MCP_TEMPLATE"
        exit 1
    fi

    # MCP 環境変数ファイルの確認
    if [[ ! -f "$MCP_ENV" ]]; then
        print_warning "MCP 環境変数ファイルが見つかりません: $MCP_ENV"
        print_info ""
        print_info "先に script/setup-env.sh を実行してください:"
        print_info "  bash $SCRIPT_DIR/setup-env.sh"
        print_info ""
        print_info "または手動で作成してください:"
        print_info "  cp $REPO_ROOT/credentials/templates/mcp.env.template $MCP_ENV"
        print_info "  # ファイルを編集して op:// 参照を実際の値に置換"
        print_info ""
        exit 1
    fi

    # MCP 環境変数を読み込み
    print_info "環境変数を読み込み中..."
    set -a
    # shellcheck disable=SC1090
    source "$MCP_ENV"
    set +a

    # envsubst で変数置換して .mcp.json を生成
    print_info ".mcp.json を生成中..."

    if envsubst < "$MCP_TEMPLATE" > "$MCP_OUTPUT"; then
        chmod 600 "$MCP_OUTPUT"
        print_success ".mcp.json を生成しました: $MCP_OUTPUT"
        print_info ""
        print_success "MCP 設定セットアップが完了しました"
    else
        print_error ".mcp.json の生成に失敗しました"
        exit 1
    fi
}

main "$@"
