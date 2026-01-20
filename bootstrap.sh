#!/usr/bin/env bash
# ============================================================================
# GitHub Codespaces Dotfiles Bootstrap Script
# 環境を検出して適切なセットアップを実行する代替スクリプト
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 環境を検出中..."

# ============================================================================
# 環境判定
# ============================================================================

# GitHub Codespaces 環境かどうか
if [ -n "${CODESPACES:-}" ]; then
    echo "🌐 GitHub Codespaces 環境を検出しました"
    ENVIRONMENT="codespaces"
# VS Code DevContainer 環境かどうか
elif [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${VSCODE_REMOTE_CONTAINERS_SESSION:-}" ]; then
    echo "🐳 VS Code DevContainer 環境を検出しました"
    ENVIRONMENT="devcontainer"
# Docker コンテナ内かどうか
elif [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "🐋 Docker コンテナ環境を検出しました"
    ENVIRONMENT="docker"
# ローカル環境
else
    echo "🖥️  ローカル環境を検出しました"
    ENVIRONMENT="local"
fi

echo "📦 環境タイプ: ${ENVIRONMENT}"

# ============================================================================
# 環境別の前処理
# ============================================================================

case "$ENVIRONMENT" in
    codespaces)
        echo ""
        echo "🔧 Codespaces 固有の設定を適用中..."

        # Codespaces 固有の環境変数設定
        export CODESPACES_SETUP=true

        # Git の安全なディレクトリ設定
        git config --global --add safe.directory "${SCRIPT_DIR}" 2>/dev/null || true

        # Codespaces のワークスペース設定
        if [ -n "${GITHUB_WORKSPACE:-}" ]; then
            git config --global --add safe.directory "${GITHUB_WORKSPACE}" 2>/dev/null || true
        fi
        ;;

    devcontainer)
        echo ""
        echo "🔧 DevContainer 固有の設定を適用中..."

        # DevContainer 固有の環境変数設定
        export DEVCONTAINER_SETUP=true

        # Git の安全なディレクトリ設定
        git config --global --add safe.directory "${SCRIPT_DIR}" 2>/dev/null || true
        ;;

    docker)
        echo ""
        echo "🔧 Docker 固有の設定を適用中..."

        # Docker 固有の環境変数設定
        export DOCKER_SETUP=true
        ;;

    local)
        echo ""
        echo "🔧 ローカル環境固有の設定を適用中..."

        # ローカル環境固有の設定
        export LOCAL_SETUP=true
        ;;
esac

# ============================================================================
# 共通セットアップの実行
# ============================================================================

echo ""
echo "🚀 共通セットアップスクリプトを実行中..."

if [ -f "${SCRIPT_DIR}/install.sh" ]; then
    bash "${SCRIPT_DIR}/install.sh"
else
    echo "❌ エラー: install.sh が見つかりません"
    exit 1
fi

# ============================================================================
# 環境別の後処理
# ============================================================================

case "$ENVIRONMENT" in
    codespaces)
        echo ""
        echo "🎯 Codespaces 固有の後処理を実行中..."

        # GitHub CLI の認証状態確認
        if command -v gh &> /dev/null; then
            if gh auth status &> /dev/null; then
                echo "  ✅ GitHub CLI は認証済みです"
            else
                echo "  ℹ️  GitHub CLI の認証が必要です。'gh auth login' を実行してください"
            fi
        fi

        # Codespaces シークレットの確認
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            echo "  ✅ GITHUB_TOKEN が設定されています"
        else
            echo "  ⚠️  GITHUB_TOKEN が設定されていません"
        fi
        ;;

    devcontainer|docker)
        echo ""
        echo "🎯 コンテナ固有の後処理を実行中..."

        # コンテナ内での Git 設定確認
        if ! git config --global user.name &> /dev/null; then
            echo "  ⚠️  Git ユーザー名が設定されていません"
            echo "     git config --global user.name \"Your Name\" を実行してください"
        fi

        if ! git config --global user.email &> /dev/null; then
            echo "  ⚠️  Git メールアドレスが設定されていません"
            echo "     git config --global user.email \"your.email@example.com\" を実行してください"
        fi
        ;;

    local)
        echo ""
        echo "🎯 ローカル環境固有の後処理を実行中..."

        # ローカル環境での追加設定
        if [ -f "${SCRIPT_DIR}/script/setup-env.sh" ]; then
            echo "  ℹ️  環境変数のセットアップが必要な場合は以下を実行してください:"
            echo "     bash ${SCRIPT_DIR}/script/setup-env.sh"
        fi
        ;;
esac

# ============================================================================
# 完了メッセージ
# ============================================================================

echo ""
echo "✅ Bootstrap セットアップが完了しました！"
echo "   環境: ${ENVIRONMENT}"
echo ""
