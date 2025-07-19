#!/usr/bin/env zsh

# Ensure REPO_PATH exists
if [[ -z "$REPO_PATH" ]]; then
    REPO_PATH=$(pwd)
fi
mkdir -p "$REPO_PATH/brew" "$REPO_PATH/vscode" "$REPO_PATH/git" "$REPO_PATH/dot" "$REPO_PATH/npm" "$REPO_PATH/.zsh"

# Determine the OS with improved detection
if [[ $(uname) = "Linux" ]]; then
	OS=linux
elif [[ $(uname) = "Darwin" ]]; then
	OS=darwin
elif [[ $(uname -s) =~ ^MINGW|^MSYS|^CYGWIN ]]; then
	OS=windows
elif [[ -n "$WINDIR" ]] || [[ -n "$SYSTEMROOT" ]]; then
	OS=windows
else
	# Fallback: assume Unix-like system for unknown platforms
	OS=unix
fi

echo "Detected OS: $OS"

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
elif [[ $OS = "windows" ]]; then
	echo "Windows detected. For optimal Windows support, please use the PowerShell script:"
	echo "  powershell.exe -ExecutionPolicy Bypass -File script/export.ps1"
	echo ""
	echo "Attempting basic export with available Unix tools..."
	
	# Try to export VSCode/Cursor extensions if available
	if type cursor >/dev/null 2>&1; then
		cursor --list-extensions > "$REPO_PATH/vscode/extensions.txt"
	elif type code >/dev/null 2>&1; then
		code --list-extensions > "$REPO_PATH/vscode/extensions.txt"
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
	elif [[ $OS = "windows" ]]; then
		# Windows may have brew via WSL or other Unix-like environments
		brew bundle dump --file "$REPO_PATH/brew/WindowsBrewfile" --force --all
		echo "Exported Homebrew packages for Windows environment"
	fi
fi

# Export general settings (only if files exist)
[[ -f ~/.gitconfig ]] && cat ~/.gitconfig > "$REPO_PATH/git/gitconfig"
[[ -f ~/.gitignore ]] && cat ~/.gitignore > "$REPO_PATH/git/gitignore"
[[ -f ~/.gitattributes ]] && cat ~/.gitattributes > "$REPO_PATH/git/gitattributes"
[[ -f ~/.zprofile ]] && cat ~/.zprofile > "$REPO_PATH/dot/.zprofile"

# Export appropriate .zshrc based on environment
if [[ $IS_DEVCONTAINER = true ]]; then
    [[ -f ~/.zshrc ]] && cat ~/.zshrc > "$REPO_PATH/dot/.zshrc.devcontainer"
else
    [[ -f ~/.zshrc ]] && cat ~/.zshrc > "$REPO_PATH/dot/.zshrc"
fi

[[ -f ~/.rubocop.yml ]] && cat ~/.rubocop.yml > "$REPO_PATH/dot/.rubocop.yml"
[[ -d ~/.zsh ]] && cp -r -f ~/.zsh "$REPO_PATH"

# Export npm packages (only if npm is available)
if type npm >/dev/null 2>&1; then
	npm list -g --depth=0 --json > "$REPO_PATH/npm/global.json" 2>/dev/null || echo '{}' > "$REPO_PATH/npm/global.json"
fi
