#!/usr/bin/env zsh

set -euo pipefail

# Ensure REPO_PATH exists
REPO_PATH="${REPO_PATH:-$(pwd)}"
mkdir -p "$REPO_PATH/brew" "$REPO_PATH/vscode" "$REPO_PATH/git" "$REPO_PATH/npm" "$REPO_PATH/.zsh"

# Determine the OS
if [[ $(uname) = "Linux" ]]; then
	OS=linux
elif [[ $(uname) = "Darwin" ]]; then
	OS=darwin
else
	OS=windows
fi

# Check if running in devcontainer/Docker environment
IS_DEVCONTAINER=false
if [[ -f /.dockerenv ]] || [[ ! -z "${REMOTE_CONTAINERS}" ]] || [[ ! -z "${CODESPACES}" ]]; then
    IS_DEVCONTAINER=true
fi

# Export settings for the specific OS
if [[ $OS = "darwin" ]]; then
	if type cursor >/dev/null 2>&1; then
		cursor --list-extensions > "$REPO_PATH/vscode/extensions.txt"
	fi
fi

# Only export brew bundle if brew is available and not in devcontainer
if type brew >/dev/null 2>&1 && [[ $IS_DEVCONTAINER = false ]]; then
	if [[ $OS = "linux" ]]; then
		brew bundle dump --file "$REPO_PATH/brew/LinuxBrewfile" --force --all
	elif [[ $OS = "darwin" ]]; then
		brew bundle dump --file "$REPO_PATH/brew/MacOSBrewfile" --force --all
		echo "" > "$REPO_PATH/brew/NoDependencyBrewfile"
		brew list | xargs -P`expr $(sysctl -n hw.ncpu) - 1` -I{} sh -c "brew uses --installed {} | wc -l | xargs -I{count} sh -c 'test {count} -eq 0 && echo {} >> $REPO_PATH/brew/NoDependencyBrewfile'"
	fi
fi

# Export general settings (only if files exist)
[[ -f ~/.gitconfig ]] && cat ~/.gitconfig > "$REPO_PATH/git/gitconfig"
[[ -f ~/.gitignore ]] && cat ~/.gitignore > "$REPO_PATH/git/gitignore"
[[ -f ~/.gitattributes ]] && cat ~/.gitattributes > "$REPO_PATH/git/gitattributes"
[[ -d ~/.zsh ]] && cp -r -f ~/.zsh "$REPO_PATH"

# Export npm packages (only if npm is available)
if type npm >/dev/null 2>&1; then
	npm list -g --depth=0 --json > "$REPO_PATH/npm/global.json" 2>/dev/null || echo '{}' > "$REPO_PATH/npm/global.json"
fi
