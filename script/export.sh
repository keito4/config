#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/platform.sh"
source "$SCRIPT_DIR/lib/config.sh"

REPO_PATH="${REPO_PATH:-$(pwd)}"
mkdir -p "$REPO_PATH/brew" "$REPO_PATH/vscode" "$REPO_PATH/git" "$REPO_PATH/npm" "$REPO_PATH/.zsh" "$REPO_PATH/dot" "$REPO_PATH/.claude" "$REPO_PATH/.codex" "$REPO_PATH/.cursor"

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
	config::filter_gitconfig ~/.gitconfig "$REPO_PATH/git/gitconfig"
fi
[[ -f ~/.gitignore ]] && cat ~/.gitignore > "$REPO_PATH/git/gitignore"
[[ -f ~/.gitattributes ]] && cat ~/.gitattributes > "$REPO_PATH/git/gitattributes"

# Zsh configuration (legacy .zsh directory)
[[ -d ~/.zsh ]] && cp -r -f ~/.zsh "$REPO_PATH"

# Individual dotfiles
[[ -f ~/.zprofile ]] && cp ~/.zprofile "$REPO_PATH/dot/.zprofile"

# Export .zshrc but filter out sensitive environment variables
if [[ -f ~/.zshrc ]]; then
	config::filter_credentials ~/.zshrc "$REPO_PATH/dot/.zshrc"
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
	config::export_claude ~/.claude "$REPO_PATH/.claude"
fi

# MCP configuration (replace API keys with placeholders)
if [[ -f ~/.mcp.json ]]; then
	config::export_mcp ~/.mcp.json "$REPO_PATH/.mcp.json"
fi

# Codex configuration
if [[ -d ~/.codex ]]; then
	config::export_codex ~/.codex "$REPO_PATH/.codex"
fi

# Cursor configuration
if [[ -d ~/.cursor ]]; then
	config::export_cursor ~/.cursor "$REPO_PATH/.cursor"
fi
