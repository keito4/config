#!/bin/sh
set -e

# Dev containerのfeatureインストール時は、必要なパッケージのみインストール
# 実際の設定は postCreateCommand で行う

# zshのインストール
if ! command -v zsh >/dev/null 2>&1; then
    echo "Installing zsh..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y zsh
    elif command -v yum >/dev/null 2>&1; then
        yum install -y zsh
    fi
fi

# 必要な基本パッケージのインストール
if command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y \
        curl \
        git \
        build-essential \
        jq
fi

# npm global directory setup for the remoteUser
if [ -n "${_REMOTE_USER}" ] && [ "${_REMOTE_USER}" != "root" ]; then
    NPM_GLOBAL_DIR="/home/${_REMOTE_USER}/.npm-global"
    mkdir -p "${NPM_GLOBAL_DIR}"
    chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${NPM_GLOBAL_DIR}"
fi

echo "Feature installation completed. Configuration will be applied by postCreateCommand."