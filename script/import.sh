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

# Legacy .zsh directory
[[ -d "$REPO_PATH/.zsh" ]] && cp -r -f "$REPO_PATH/.zsh" ~/

# Git configuration
[[ -d "$REPO_PATH/git" ]] && cp -r -f "$REPO_PATH/git" ~/
[[ -f "$REPO_PATH/git/gitconfig" ]] && cp "$REPO_PATH/git/gitconfig" ~/.gitconfig
[[ -f "$REPO_PATH/git/gitignore" ]] && cp "$REPO_PATH/git/gitignore" ~/.gitignore
[[ -f "$REPO_PATH/git/gitattributes" ]] && cp "$REPO_PATH/git/gitattributes" ~/.gitattributes

# Individual dotfiles
[[ -f "$REPO_PATH/dot/.zprofile" ]] && cp "$REPO_PATH/dot/.zprofile" ~/.zprofile
[[ -f "$REPO_PATH/dot/.zshrc" ]] && cp "$REPO_PATH/dot/.zshrc" ~/.zshrc
[[ -f "$REPO_PATH/dot/.zshrc.devcontainer" ]] && cp "$REPO_PATH/dot/.zshrc.devcontainer" ~/.zshrc.devcontainer

# Peco configuration
if [[ -d "$REPO_PATH/dot/.peco" ]]; then
	mkdir -p ~/.peco
	cp -r "$REPO_PATH/dot/.peco"/* ~/.peco/
fi

# Claude Code shared configuration
if [[ -d "$REPO_PATH/.claude" ]]; then
	mkdir -p ~/.claude

	# Copy shared settings (not settings.local.json)
	[[ -f "$REPO_PATH/.claude/settings.json" ]] && cp "$REPO_PATH/.claude/settings.json" ~/.claude/settings.json
	[[ -f "$REPO_PATH/.claude/CLAUDE.md" ]] && cp "$REPO_PATH/.claude/CLAUDE.md" ~/.claude/CLAUDE.md

	# Copy commands, agents, hooks directories
	if [[ -d "$REPO_PATH/.claude/commands" ]]; then
		mkdir -p ~/.claude/commands
		cp -r "$REPO_PATH/.claude/commands"/* ~/.claude/commands/ 2>/dev/null || true
	fi
	if [[ -d "$REPO_PATH/.claude/agents" ]]; then
		mkdir -p ~/.claude/agents
		cp -r "$REPO_PATH/.claude/agents"/* ~/.claude/agents/ 2>/dev/null || true
	fi
	if [[ -d "$REPO_PATH/.claude/hooks" ]]; then
		mkdir -p ~/.claude/hooks
		cp -r "$REPO_PATH/.claude/hooks"/* ~/.claude/hooks/ 2>/dev/null || true
	fi

	# Copy plugin configuration (not installed plugins)
	if [[ -d "$REPO_PATH/.claude/plugins" ]]; then
		mkdir -p ~/.claude/plugins
		[[ -f "$REPO_PATH/.claude/plugins/config.json" ]] && cp "$REPO_PATH/.claude/plugins/config.json" ~/.claude/plugins/config.json
		[[ -f "$REPO_PATH/.claude/plugins/known_marketplaces.json" ]] && cp "$REPO_PATH/.claude/plugins/known_marketplaces.json" ~/.claude/plugins/known_marketplaces.json
	fi
fi

if devcontainer::is_active; then
	devcontainer::bootstrap
fi

# npm global packages
if type jq >/dev/null 2>&1 && type npm >/dev/null 2>&1; then
	npm install -g $(jq -r '.dependencies | keys | .[]' "$REPO_PATH/npm/global.json")
fi

# Clone repositories using ghq
if type gh >/dev/null 2>&1 && type ghq >/dev/null 2>&1; then
	gh api user/repos | jq -r '.[].ssh_url' | xargs -L1 ghq get
fi
