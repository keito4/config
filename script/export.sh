#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/platform.sh"

REPO_PATH="${REPO_PATH:-$(pwd)}"
mkdir -p "$REPO_PATH/brew" "$REPO_PATH/vscode" "$REPO_PATH/git" "$REPO_PATH/npm" "$REPO_PATH/.zsh" "$REPO_PATH/dot" "$REPO_PATH/.claude"

export_extensions_darwin() {
	if type cursor >/dev/null 2>&1; then
		cursor --list-extensions > "$REPO_PATH/vscode/extensions.txt"
	fi
}

export_brew_bundle_linux() {
	brew bundle dump --file "$REPO_PATH/brew/LinuxBrewfile" --force --all
}

export_brew_bundle_darwin() {
	brew bundle dump --file "$REPO_PATH/brew/MacOSBrewfile" --force --all
}

platform::run_task export_extensions

if type brew >/dev/null 2>&1 && [[ "${PLATFORM_IN_DEVCONTAINER}" = false ]]; then
	platform::run_task export_brew_bundle
fi

# Git configuration (exclude personal information)
if [[ -f ~/.gitconfig ]]; then
	# Filter out user-specific information (name, email, signingkey) from [user] section
	# Use sed to comment out sensitive fields in [user] section
	sed -E '/^\[user\]/,/^\[/{
		s/^[[:space:]]*(name)[[:space:]]*=.*$/	# \1 = # Configure with: git config --global user.name "Your Name"/
		s/^[[:space:]]*(email)[[:space:]]*=.*$/	# \1 = # Configure with: git config --global user.email "your.email@example.com"/
		s/^[[:space:]]*(signingkey)[[:space:]]*=.*$/	# \1 = # Configure with: git config --global user.signingkey "$(cat ~\/.ssh\/id_ed25519.pub)"/
	}' ~/.gitconfig > "$REPO_PATH/git/gitconfig"
fi
[[ -f ~/.gitignore ]] && cat ~/.gitignore > "$REPO_PATH/git/gitignore"
[[ -f ~/.gitattributes ]] && cat ~/.gitattributes > "$REPO_PATH/git/gitattributes"

# Zsh configuration (legacy .zsh directory)
[[ -d ~/.zsh ]] && cp -r -f ~/.zsh "$REPO_PATH"

# Individual dotfiles
[[ -f ~/.zprofile ]] && cp ~/.zprofile "$REPO_PATH/dot/.zprofile"

# Export .zshrc but filter out sensitive environment variables
if [[ -f ~/.zshrc ]]; then
	grep -v -E 'export\s+(NPM_TOKEN|BUNDLE_RUBYGEMS__[A-Z_]*|[A-Z_]*TOKEN|[A-Z_]*SECRET|[A-Z_]*PASSWORD|[A-Z_]*API_KEY|[A-Z_]*CREDENTIAL)=' ~/.zshrc > "$REPO_PATH/dot/.zshrc" || cp ~/.zshrc "$REPO_PATH/dot/.zshrc"
fi

[[ -f ~/.zshrc.devcontainer ]] && cp ~/.zshrc.devcontainer "$REPO_PATH/dot/.zshrc.devcontainer"

# Peco configuration
if [[ -d ~/.peco ]]; then
	mkdir -p "$REPO_PATH/dot/.peco"
	cp -r ~/.peco/* "$REPO_PATH/dot/.peco/"
fi

# npm global packages
if type npm >/dev/null 2>&1; then
	npm list -g --depth=0 --json > "$REPO_PATH/npm/global.json" 2>/dev/null || echo '{}' > "$REPO_PATH/npm/global.json"
fi

# Claude Code shared configuration (exclude local-only files)
if [[ -d ~/.claude ]]; then
	# Copy shared settings (not settings.local.json)
	[[ -f ~/.claude/settings.json ]] && cp ~/.claude/settings.json "$REPO_PATH/.claude/settings.json"
	[[ -f ~/.claude/CLAUDE.md ]] && cp ~/.claude/CLAUDE.md "$REPO_PATH/.claude/CLAUDE.md"

	# Copy commands, agents, hooks, plugins directories
	if [[ -d ~/.claude/commands ]] && [[ -n "$(ls -A ~/.claude/commands 2>/dev/null)" ]]; then
		mkdir -p "$REPO_PATH/.claude/commands"
		cp -r ~/.claude/commands/* "$REPO_PATH/.claude/commands/" 2>/dev/null || true
	fi
	if [[ -d ~/.claude/agents ]] && [[ -n "$(ls -A ~/.claude/agents 2>/dev/null)" ]]; then
		mkdir -p "$REPO_PATH/.claude/agents"
		cp -r ~/.claude/agents/* "$REPO_PATH/.claude/agents/" 2>/dev/null || true
	fi
	if [[ -d ~/.claude/hooks ]] && [[ -n "$(ls -A ~/.claude/hooks 2>/dev/null)" ]]; then
		mkdir -p "$REPO_PATH/.claude/hooks"
		cp -r ~/.claude/hooks/* "$REPO_PATH/.claude/hooks/" 2>/dev/null || true
	fi

	# Copy plugin configuration (not installed plugins or marketplace files)
	if [[ -d ~/.claude/plugins ]]; then
		mkdir -p "$REPO_PATH/.claude/plugins"
		[[ -f ~/.claude/plugins/config.json ]] && cp ~/.claude/plugins/config.json "$REPO_PATH/.claude/plugins/config.json"
		[[ -f ~/.claude/plugins/known_marketplaces.json ]] && cp ~/.claude/plugins/known_marketplaces.json "$REPO_PATH/.claude/plugins/known_marketplaces.json"
	fi
fi
