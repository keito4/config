#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/platform.sh"

REPO_PATH="${REPO_PATH:-$(pwd)}"
mkdir -p "$REPO_PATH/brew" "$REPO_PATH/vscode" "$REPO_PATH/git" "$REPO_PATH/npm" "$REPO_PATH/.zsh"

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

[[ -f ~/.gitconfig ]] && cat ~/.gitconfig > "$REPO_PATH/git/gitconfig"
[[ -f ~/.gitignore ]] && cat ~/.gitignore > "$REPO_PATH/git/gitignore"
[[ -f ~/.gitattributes ]] && cat ~/.gitattributes > "$REPO_PATH/git/gitattributes"
[[ -d ~/.zsh ]] && cp -r -f ~/.zsh "$REPO_PATH"

if type npm >/dev/null 2>&1; then
	npm list -g --depth=0 --json > "$REPO_PATH/npm/global.json" 2>/dev/null || echo '{}' > "$REPO_PATH/npm/global.json"
fi
