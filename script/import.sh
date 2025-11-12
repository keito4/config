#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/devcontainer.sh"

platform::assert_supported

if [[ "${PLATFORM_IN_DEVCONTAINER}" = true ]]; then
	export NONINTERACTIVE=1
	export RUNZSH=no
	export CHSH=no
	export KEEP_ZSHRC=yes
fi

if ! type brew >/dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
fi

REPO_PATH="${REPO_PATH:-$(pwd)}"

install_packages_linux() {
	if type brew >/dev/null 2>&1; then
		brew bundle --file "$REPO_PATH/brew/LinuxBrewfile"
	fi
}

install_packages_darwin() {
	if type brew >/dev/null 2>&1; then
		brew bundle --file "$REPO_PATH/brew/MacOSBrewfile"
	fi
	if type cursor >/dev/null 2>&1 && [[ -f "$REPO_PATH/vscode/extensions.txt" ]]; then
		<"$REPO_PATH/vscode/extensions.txt" xargs -L1 cursor --install-extension
	fi
}

if [[ ! -d ~/.oh-my-zsh ]]; then
	env RUNZSH=${RUNZSH:-no} CHSH=${CHSH:-no} KEEP_ZSHRC=${KEEP_ZSHRC:-yes} \
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
fi

platform::run_task install_packages

cp -r -f "$REPO_PATH/.zsh" ~/
cp -r -f "$REPO_PATH/git" ~/
cp "$REPO_PATH/git/gitconfig" ~/.gitconfig
cp "$REPO_PATH/git/gitignore" ~/.gitignore
cp "$REPO_PATH/git/gitattributes" ~/.gitattributes

if devcontainer::is_active; then
	devcontainer::bootstrap
fi

if type jq >/dev/null 2>&1 && type npm >/dev/null 2>&1; then
	npm install -g $(jq -r '.dependencies | keys | .[]' "$REPO_PATH/npm/global.json")
fi

if type gh >/dev/null 2>&1 && type ghq >/dev/null 2>&1; then
	gh api user/repos | jq -r '.[].ssh_url' | xargs -L1 ghq get
fi
