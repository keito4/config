#!/bin/zsh

# Ensure REPO_PATH exists
if [[ -z "$REPO_PATH" ]]; then
    REPO_PATH=$(pwd)
fi
mkdir -p "$REPO_PATH/brew" "$REPO_PATH/vscode" "$REPO_PATH/git" "$REPO_PATH/dot" "$REPO_PATH/npm" "$REPO_PATH/.zsh"

# Determine the OS
if [[ $(uname) = "Linux" ]]; then
	OS=linux
elif [[ $(uname) = "Darwin" ]]; then
	OS=darwin
else
	OS=windows
fi

# Export settings for the specific OS
if [[ $OS = "darwin" ]]; then
	cursor --list-extensions > "$REPO_PATH/vscode/extensions.txt"
fi

if [[ $OS = "linux" ]]; then
	brew bundle dump --file "$REPO_PATH/brew/LinuxBrewfile" --force --all
elif [[ $OS = "darwin" ]]; then
	brew bundle dump --file "$REPO_PATH/brew/MacOSBrewfile" --force --all
	echo "" > "$REPO_PATH/brew/NoDependencyBrewfile"
	brew list | xargs -P`expr $(sysctl -n hw.ncpu) - 1` -I{} sh -c "brew uses --installed {} | wc -l | xargs -I{count} sh -c 'test {count} -eq 0 && echo {} >> $REPO_PATH/brew/NoDependencyBrewfile'"
fi

# Export general settings
cat ~/.git/gitconfig > "$REPO_PATH/git/gitconfig"
cat ~/.git/gitignore > "$REPO_PATH/git/gitignore"
cat ~/.git/gitattributes > "$REPO_PATH/git/gitattributes"
cat ~/.zprofile > "$REPO_PATH/dot/.zprofile"
cat ~/.zshrc > "$REPO_PATH/dot/.zshrc"
cat ~/.rubocop.yml > "$REPO_PATH/dot/.rubocop.yml"
cp -r -f ~/.zsh "$REPO_PATH"
npm list -g --depth=0 --json > "$REPO_PATH/npm/global.json"
