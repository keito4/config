#!/usr/bin/env bash
# 環境変数セットアップスクリプト
# 1Password CLI を使用して環境変数ファイルを生成します

set -euo pipefail

# ディレクトリパス
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$REPO_ROOT/credentials/templates"
CREDENTIALS_DIR="$REPO_ROOT/credentials"

# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"

# 1Password CLI の利用可否をチェック
check_op_cli() {
    if ! command -v op >/dev/null 2>&1; then
        return 1
    fi

    # op account list でサインイン状態を確認
    if ! op account list >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

# テンプレートから環境ファイルを生成
generate_env_file() {
    local template_file="$1"
    local output_file="$2"
    local description="$3"

    if [[ ! -f "$template_file" ]]; then
        print_error "テンプレートファイルが見つかりません: $template_file"
        return 1
    fi

    print_info "生成中: $description..."

    if check_op_cli; then
        # 1Password CLI を使用して環境変数を展開
        local op_result

        # OP_ACCOUNT が設定されている場合は --account フラグを追加
        if [[ -n "${OP_ACCOUNT:-}" ]]; then
            op inject --account="$OP_ACCOUNT" --force -i "$template_file" -o "$output_file" 2>&1
            op_result=$?
        else
            op inject --force -i "$template_file" -o "$output_file" 2>&1
            op_result=$?
        fi

        if [[ $op_result -eq 0 ]]; then
            chmod 600 "$output_file"
            print_success "$description を生成しました: $output_file"
            return 0
        else
            print_error "1Password からの取得に失敗しました"
            print_info "ヒント: 複数の 1Password アカウントがある場合は OP_ACCOUNT 環境変数を設定してください"
            print_info "例: OP_ACCOUNT=my.1password.com bash script/setup-env.sh"
            return 1
        fi
    else
        print_warning "1Password CLI が利用できません"
        return 1
    fi
}

# メイン処理
main() {
    print_info "環境変数セットアップを開始します"
    print_info ""

    # 1Password CLI の確認
    if ! check_op_cli; then
        print_warning "1Password CLI が利用できません"
        print_info ""
        print_info "以下のいずれかの方法で設定してください："
        print_info "1. 1Password CLI をインストール:"
        print_info "   brew install --cask 1password-cli"
        print_info "   op signin"
        print_info ""
        print_info "2. 手動で環境ファイルを作成:"
        print_info "   cp $TEMPLATES_DIR/devcontainer.env.template ~/.devcontainer.env"
        print_info "   cp $TEMPLATES_DIR/mcp.env.template $CREDENTIALS_DIR/mcp.env"
        print_info "   # ファイルを編集して op:// 参照を実際の値に置換"
        print_info ""
        exit 1
    fi

    print_success "1Password CLI が利用可能です"
    print_info ""

    # credentials ディレクトリが存在することを確認
    mkdir -p "$CREDENTIALS_DIR"

    # DevContainer 用環境ファイル生成
    if generate_env_file \
        "$TEMPLATES_DIR/devcontainer.env.template" \
        "$HOME/.devcontainer.env" \
        "DevContainer 環境変数"; then
        :
    else
        print_error "DevContainer 環境変数の生成に失敗しました"
        exit 1
    fi

    # MCP 用環境ファイル生成
    if generate_env_file \
        "$TEMPLATES_DIR/mcp.env.template" \
        "$CREDENTIALS_DIR/mcp.env" \
        "MCP 環境変数"; then
        :
    else
        print_error "MCP 環境変数の生成に失敗しました"
        exit 1
    fi

    print_info ""
    print_success "環境変数セットアップが完了しました"
}

main "$@"
