#!/usr/bin/env bash
# ============================================================================
# GitHub Codespaces Dotfiles Installer
# GitHub Codespaces が自動的に実行するセットアップスクリプト
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Dotfiles セットアップを開始します..."
echo "📁 リポジトリディレクトリ: ${SCRIPT_DIR}"

# ============================================================================
# シンボリックリンク作成
# ============================================================================

echo ""
echo "🔗 シンボリックリンクを作成中..."

# Zsh 設定
if [ -f "${SCRIPT_DIR}/dot/.zshrc" ]; then
    ln -sf "${SCRIPT_DIR}/dot/.zshrc" "$HOME/.zshrc"
    echo "  ✅ .zshrc"
fi

if [ -f "${SCRIPT_DIR}/dot/.zprofile" ]; then
    ln -sf "${SCRIPT_DIR}/dot/.zprofile" "$HOME/.zprofile"
    echo "  ✅ .zprofile"
fi

# Git 設定
if [ -f "${SCRIPT_DIR}/git/gitconfig" ]; then
    ln -sf "${SCRIPT_DIR}/git/gitconfig" "$HOME/.gitconfig"
    echo "  ✅ .gitconfig"
fi

if [ -f "${SCRIPT_DIR}/git/gitignore" ]; then
    ln -sf "${SCRIPT_DIR}/git/gitignore" "$HOME/.gitignore_global"
    git config --global core.excludesfile "$HOME/.gitignore_global" 2>/dev/null || true
    echo "  ✅ .gitignore_global"
fi

# Git 設定ディレクトリ（モジュラー設定）
if [ -d "${SCRIPT_DIR}/git/gitconfig.d" ]; then
    mkdir -p "$HOME/.config/git"
    for file in "${SCRIPT_DIR}/git/gitconfig.d"/*; do
        if [ -f "$file" ]; then
            ln -sf "$file" "$HOME/.config/git/$(basename "$file")"
            echo "  ✅ gitconfig.d/$(basename "$file")"
        fi
    done
fi

# act 設定
if [ -f "${SCRIPT_DIR}/.actrc" ]; then
    ln -sf "${SCRIPT_DIR}/.actrc" "$HOME/.actrc"
    echo "  ✅ .actrc"
fi

# peco 設定
if [ -d "${SCRIPT_DIR}/dot/.peco" ]; then
    ln -sf "${SCRIPT_DIR}/dot/.peco" "$HOME/.peco"
    echo "  ✅ .peco/"
fi

# ============================================================================
# VS Code 拡張機能のインストール
# ============================================================================

if command -v code &> /dev/null && [ -f "${SCRIPT_DIR}/vscode/extensions.txt" ]; then
    echo ""
    echo "🔌 VS Code 拡張機能をインストール中..."

    installed=0
    skipped=0

    while IFS= read -r ext || [ -n "$ext" ]; do
        # 空行とコメント行をスキップ
        [[ -z "$ext" || "$ext" =~ ^[[:space:]]*# ]] && continue

        # 前後の空白を除去
        ext=$(echo "$ext" | xargs)
        [[ -z "$ext" ]] && continue

        if code --install-extension "$ext" --force > /dev/null 2>&1; then
            echo "  ✅ ${ext}"
            installed=$((installed + 1))
        else
            echo "  ⚠️  ${ext} (スキップ)"
            skipped=$((skipped + 1))
        fi
    done < "${SCRIPT_DIR}/vscode/extensions.txt"

    echo "  📊 インストール完了: ${installed} 個、スキップ: ${skipped} 個"
else
    echo ""
    echo "⏭️  VS Code が見つからないため、拡張機能のインストールをスキップします"
fi

# ============================================================================
# Claude プラグインのインストール（オプション）
# ============================================================================

if command -v claude &> /dev/null; then
    PLUGINS_FILE="${HOME}/.claude/plugins/plugins.txt"

    if [ -f "$PLUGINS_FILE" ]; then
        echo ""
        echo "🤖 Claude プラグインをインストール中..."

        if [ -f "${SCRIPT_DIR}/script/install-claude-plugins.sh" ]; then
            bash "${SCRIPT_DIR}/script/install-claude-plugins.sh" "$PLUGINS_FILE" || true
        else
            echo "  ⚠️  install-claude-plugins.sh が見つかりません"
        fi
    else
        echo ""
        echo "⏭️  Claude プラグインリストが見つからないため、スキップします"
    fi
else
    echo ""
    echo "⏭️  Claude が見つからないため、プラグインのインストールをスキップします"
fi

# ============================================================================
# Homebrew パッケージのインストール（オプション）
# ============================================================================

if command -v brew &> /dev/null && [ -f "${SCRIPT_DIR}/brew/StandaloneBrewfile" ]; then
    echo ""
    echo "🍺 Homebrew パッケージをインストールしますか？"
    echo "   (スキップする場合は Ctrl+C を押してください。10秒後に自動的にスキップします)"

    if read -t 10 -r -p "   インストールを開始する場合は Enter を押してください: "; then
        echo ""
        echo "📦 Homebrew パッケージをインストール中..."
        brew bundle --file="${SCRIPT_DIR}/brew/StandaloneBrewfile" || true
    else
        echo ""
        echo "⏭️  Homebrew パッケージのインストールをスキップしました"
    fi
fi

# ============================================================================
# 完了メッセージ
# ============================================================================

echo ""
echo "✅ Dotfiles セットアップが完了しました！"
echo ""
echo "📝 次のステップ:"
echo "   1. Git ユーザー情報を設定してください:"
echo "      git config --global user.name \"Your Name\""
echo "      git config --global user.email \"your.email@example.com\""
echo ""
echo "   2. SSH キーを設定してください:"
echo "      git config --global user.signingkey \"\$(cat ~/.ssh/id_ed25519.pub)\""
echo ""
echo "   3. シェルを再起動して変更を反映してください:"
echo "      exec \$SHELL -l"
echo ""
