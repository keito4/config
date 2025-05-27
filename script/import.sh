#!/usr/bin/env zsh

# Determine the OS
if [[ $(uname) = "Linux" ]]; then
        OS=linux
elif [[ $(uname) = "Darwin" ]]; then
	OS=darwin
else
	echo "Unsupported OS"
	exit 1
fi

# If running inside a Docker container, suppress prompts during installs
if [[ -f /.dockerenv ]]; then
        export NONINTERACTIVE=1
        export RUNZSH=no
        export CHSH=no
        export KEEP_ZSHRC=yes
fi

# install Homebrew if brew is not installed
if ! type brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
fi

# if REPO_PATH is not set, set it to the current directory
if [[ -z $REPO_PATH ]]; then
	REPO_PATH=$(pwd)
fi

# Install oh-my-zsh if not already installed
if [[ ! -d ~/.oh-my-zsh ]]; then
        env RUNZSH=${RUNZSH:-no} CHSH=${CHSH:-no} KEEP_ZSHRC=${KEEP_ZSHRC:-yes} \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zsh-autosuggestions plugin if not already installed
if [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
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

# Use devcontainer-specific .zshrc if in container environment
if [[ -f /.dockerenv ]] || [[ ! -z "${REMOTE_CONTAINERS}" ]] || [[ ! -z "${CODESPACES}" ]]; then
    cp "$REPO_PATH/dot/.zshrc.devcontainer" ~/.zshrc
else
    cp "$REPO_PATH/dot/.zshrc" ~/
fi

cp "$REPO_PATH/dot/.rubocop.yml" ~/
cp -r -f "$REPO_PATH/dot/.peco" ~/
cp -r -f "$REPO_PATH/git" ~/

if type jq >/dev/null 2>&1 && type npm >/dev/null 2>&1; then
	npm install -g $(jq -r '.dependencies | keys | .[]' "$REPO_PATH/npm/global.json")
fi

if type gh >/dev/null 2>&1 && type ghq >/dev/null 2>&1; then
	gh api user/repos | jq -r '.[].ssh_url' | xargs -L1 ghq get
fi
