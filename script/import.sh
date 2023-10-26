#!/bin/zsh

# Determine the OS
if [[ $(uname) = "Linux" ]]; then
	OS=linux
elif [[ $(uname) = "Darwin" ]]; then
	OS=darwin
else
	OS=windows
fi

# install brew if brew is not installed
if ! type brew > /dev/null 2>&1; then
	if [[ $OS = "linux" ]]; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
	elif [[ $OS = "darwin" ]]; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
fi

# if REPO_PATH is not set, set it to the current directory
if [[ -z $REPO_PATH ]]; then
	REPO_PATH=$(pwd)
fi

# Install oh-my-zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Import settings for the specific OS
if [[ $OS = "linux" ]]; then
	brew bundle --file "$REPO_PATH/brew/LinuxBrewfile"
elif [[ $OS = "darwin" ]]; then
	brew bundle --file "$REPO_PATH/brew/MacOSBrewfile"
	cat "$REPO_PATH/vscode/extensions.txt" | xargs -I@ cursor --install-extension @
	op inject --in-file "$REPO_PATH/.zsh/configs/pre/.env.secret.template" --out-file "$REPO_PATH/.zsh/configs/pre/.env.secret"
fi


# Import general settings
cp -r -f "$REPO_PATH/.zsh" ~/
cp "$REPO_PATH/dot/.zprofile" ~/
cp "$REPO_PATH/dot/.zshrc" ~/
cp "$REPO_PATH/dot/.rubocop.yml" ~/
cp -r -f "$REPO_PATH/git" ~/
npm install -g $(jq -r '.dependencies | keys | .[]' "$REPO_PATH/npm/global.json")

gh api user/repos | jq -r '.[].ssh_url' | xargs -L1 ghq get
