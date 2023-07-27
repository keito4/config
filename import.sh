#!/bin/zsh

# Determine the OS
if [[ $(uname) = "Linux" ]]; then
	OS=linux
elif [[ $(uname) = "Darwin" ]]; then
	OS=darwin
else
	OS=windows
fi

# Import settings for the specific OS
if [[ $OS = "linux" ]]; then
	brew bundle --file ./brew/LinuxBrewfile
elif [[ $OS = "darwin" ]]; then
	brew bundle --file ./brew/MacOSBrewfile
	cat ./vscode/extensions.txt | xargs -I@ code --install-extension @
fi

# Import general settings
cp -r -f .zsh ~
cp ./dot/.zprofile ~/
cp ./dot/.zshrc ~/
cp ./dot/.rubocop.yml ~/
cp -r -f ./git ~/
