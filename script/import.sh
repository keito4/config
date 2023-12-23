#!/bin/zsh

# Determine the OS
if [[ $(uname) = "Linux" ]]; then
	OS=linux
elif [[ $(uname) = "Darwin" ]]; then
	OS=darwin
else
	echo "Unsupported OS"
	exit 1
fi

# install Homebrew if brew is not installed
if ! type brew >/dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# if REPO_PATH is not set, set it to the current directory
if [[ -z $REPO_PATH ]]; then
	REPO_PATH=$(pwd)
fi

# Install oh-my-zsh if not already installed
if [[ ! -d ~/.oh-my-zsh ]]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Import settings for the specific OS
if [[ $OS = "linux" ]]; then
	if type brew >/dev/null 2>&1; then
		brew bundle --file "$REPO_PATH/brew/LinuxBrewfile"
	fi
elif [[ $OS = "darwin" ]]; then
	if type brew >/dev/null 2>&1; then
		brew bundle --file "$REPO_PATH/brew/MacOSBrewfile"
	fi
	if type code >/dev/null 2>&1; then
		cat "$REPO_PATH/vscode/extensions.txt" | xargs -L1 cursor --install-extension
	fi
	if type op >/dev/null 2>&1; then
		op inject --in-file "$REPO_PATH/.zsh/configs/pre/.env.secret.template" --out-file "$REPO_PATH/.zsh/configs/pre/.env.secret"
	fi
fi

# Import general settings
cp -r -f "$REPO_PATH/.zsh" ~/
cp "$REPO_PATH/dot/.zprofile" ~/
cp "$REPO_PATH/dot/.zshrc" ~/
cp "$REPO_PATH/dot/.rubocop.yml" ~/
cp -r -f "$REPO_PATH/git" ~/

if type jq >/dev/null 2>&1 && type npm >/dev/null 2>&1; then
	npm install -g $(jq -r '.dependencies | keys | .[]' "$REPO_PATH/npm/global.json")
fi

if type gh >/dev/null 2>&1 && type ghq >/dev/null 2>&1; then
	gh api user/repos | jq -r '.[].ssh_url' | xargs -L1 ghq get
fi
