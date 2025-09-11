#!/usr/bin/env zsh

set -euo pipefail

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
REPO_PATH="${REPO_PATH:-$(pwd)}"

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
fi

# Import general settings
cp -r -f "$REPO_PATH/.zsh" ~/
cp -r -f "$REPO_PATH/git" ~/

# Configure git settings
cp "$REPO_PATH/git/gitconfig" ~/.gitconfig
cp "$REPO_PATH/git/gitignore" ~/.gitignore

# In devcontainer, update gitconfig to use 1password-cli instead of macOS app
if [[ -f /.dockerenv ]] || [[ ! -z "${REMOTE_CONTAINERS}" ]] || [[ ! -z "${CODESPACES}" ]]; then
    # Set git user configuration explicitly
    # TODO: These values should be parameterized or set via environment variables
    # for better security and reusability across different users
    git config --global user.name "keito4"
    git config --global user.email "newton30000@gmail.com"

    # Remove all problematic github: URL aliases for devcontainer
    git config --global --remove-section url."github:" 2>/dev/null || true
    git config --global --unset-all url."github:".insteadof 2>/dev/null || true

    # Install 1password CLI if not available
    if ! command -v op >/dev/null 2>&1; then
        echo "Installing 1Password CLI..."
        curl -sS https://downloads.1password.com/linux/debian/amd64/stable/1password-cli-amd64-latest.deb -o /tmp/1password-cli.deb
        sudo dpkg -i /tmp/1password-cli.deb
        rm /tmp/1password-cli.deb
    fi

    # Check if op-ssh-sign is available after installation
    if command -v op >/dev/null 2>&1; then
        # Update the gpg.ssh.program path to use 1password-cli
        git config --global gpg.ssh.program "op-ssh-sign"
        echo "1Password SSH signing configured"
    else
        echo "Warning: 1Password CLI installation failed, disabling GPG signing"
        git config --global commit.gpgsign false
    fi
fi

if type jq >/dev/null 2>&1 && type npm >/dev/null 2>&1; then
	npm install -g $(jq -r '.dependencies | keys | .[]' "$REPO_PATH/npm/global.json")
fi

if type gh >/dev/null 2>&1 && type ghq >/dev/null 2>&1; then
	gh api user/repos | jq -r '.[].ssh_url' | xargs -L1 ghq get
fi
