#!/usr/bin/env bash
# ============================================================================
# 環境変数セットアップスクリプト
# credentials.sh のラッパースクリプト
# ============================================================================
# このスクリプトは credentials.sh を使用して環境変数ファイルを生成します。
# 後方互換性のために維持されていますが、新規利用は credentials.sh を推奨します。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_DIR="$REPO_ROOT/credentials"

# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"

main() {
    print_info "環境変数セットアップを開始します"
    print_info ""

    # credentials.sh を使用してすべてのクレデンシャルを取得
    if "$SCRIPT_DIR/credentials.sh" fetch; then
        print_info ""

        # DevContainer 用環境ファイルをホームディレクトリにコピー
        if [[ -f "$CREDENTIALS_DIR/devcontainer.env" ]]; then
            cp "$CREDENTIALS_DIR/devcontainer.env" "$HOME/.devcontainer.env"
            chmod 600 "$HOME/.devcontainer.env"
            print_success "DevContainer 環境変数を ~/.devcontainer.env にコピーしました"
        fi

        print_info ""
        print_success "環境変数セットアップが完了しました"
    else
        print_error "クレデンシャルの取得に失敗しました"
        print_info ""
        print_info "以下のいずれかの方法で設定してください："
        print_info "1. 1Password CLI をインストール:"
        print_info "   brew install --cask 1password-cli"
        print_info "   op signin"
        print_info ""
        print_info "2. 手動で環境ファイルを作成:"
        print_info "   cp $CREDENTIALS_DIR/templates/devcontainer.env.template ~/.devcontainer.env"
        print_info "   # ファイルを編集して op:// 参照を実際の値に置換"
        print_info ""
        exit 1
    fi
}

main "$@"
