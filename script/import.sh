#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/devcontainer.sh"
source "$SCRIPT_DIR/lib/config.sh"

platform::assert_supported
platform::assert_not_windows

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
	# macOS packages are managed by nix-darwin. Run: make nix-switch
	echo "macOS: Packages are managed by nix-darwin. Run 'make nix-switch' to apply."
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

# Legacy .zsh directory
[[ -d "$REPO_PATH/.zsh" ]] && cp -r -f "$REPO_PATH/.zsh" ~/

# Git configuration
[[ -d "$REPO_PATH/git" ]] && cp -r -f "$REPO_PATH/git" ~/

# Import gitconfig with warning about missing personal info
if [[ -f "$REPO_PATH/git/gitconfig" ]]; then
	cp "$REPO_PATH/git/gitconfig" ~/.gitconfig
	echo "⚠️  注意: ~/.gitconfig に個人情報がコメントアウトされています"
	echo "    以下のコマンドで設定してください:"
	echo "    git config --global user.name \"Your Name\""
	echo "    git config --global user.email \"your.email@example.com\""
	echo "    git config --global user.signingkey ~/.ssh/id_ed25519.pub"
fi

[[ -f "$REPO_PATH/git/gitignore" ]] && cp "$REPO_PATH/git/gitignore" ~/.gitignore
[[ -f "$REPO_PATH/git/gitattributes" ]] && cp "$REPO_PATH/git/gitattributes" ~/.gitattributes

# Individual dotfiles
# macOS: .zshrc and .zprofile are managed by nix home-manager (nix/home/zsh.nix)
[[ -f "$REPO_PATH/dot/.zshrc.devcontainer" ]] && cp "$REPO_PATH/dot/.zshrc.devcontainer" ~/.zshrc.devcontainer

# Peco configuration
if [[ -d "$REPO_PATH/dot/.peco" ]]; then
	mkdir -p ~/.peco
	cp -r "$REPO_PATH/dot/.peco"/* ~/.peco/
fi

# Claude Code shared configuration
if [[ -d "$REPO_PATH/.claude" ]]; then
	config::import_claude "$REPO_PATH/.claude" ~/.claude
fi

# MCP configuration
if [[ -f "$REPO_PATH/.mcp.json" ]]; then
	config::import_mcp "$REPO_PATH/.mcp.json" ~/.mcp.json
fi

# Codex configuration
if [[ -d "$REPO_PATH/.codex" ]]; then
	config::import_codex "$REPO_PATH/.codex" ~/.codex
fi

# Cursor configuration
if [[ -d "$REPO_PATH/.cursor" ]]; then
	config::import_cursor "$REPO_PATH/.cursor" ~/.cursor
fi

# Gemini configuration
if [[ -d "$REPO_PATH/.gemini" ]]; then
	config::import_gemini "$REPO_PATH/.gemini" ~/.gemini
fi

if devcontainer::is_active; then
	devcontainer::bootstrap
fi

# npm global packages
if type jq >/dev/null 2>&1 && type npm >/dev/null 2>&1; then
	npm install -g $(jq -r '.dependencies | to_entries[] | "\(.key)@\(.value.version)"' "$REPO_PATH/npm/global.json")
fi

# Clone repositories using ghq
if type gh >/dev/null 2>&1 && type ghq >/dev/null 2>&1; then
	gh api user/repos --paginate | jq -r '.[].ssh_url' | xargs -L1 ghq get
fi
