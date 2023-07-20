#!/bin/zsh

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
	code --list-extensions > ./vscode/extensions.txt
	cat ~/Library/Application\ Support/Code/User/settings.json > ./vscode/settings.json
	cat ~/Library/Application\ Support/Code/User/keybindings.json > ./vscode/keybindings.json
fi

if [[ $OS = "linux" ]]; then
	brew bundle dump --file ./brew/LinuxBrewfile --force --all
elif [[ $OS = "darwin" ]]; then
	brew bundle dump --file ./brew/MacOSBrewfile --force --all
fi

# Export general settings
cat ~/.git/gitconfig > ./git/gitconfig
cat ~/.git/gitignore > ./git/gitignore
cat ~/.git/gitattributes > ./git/gitattributes
cat ~/.zprofile > ./dot/.zprofile
cat ~/.zshrc > ./dot/.zshrc
cat ~/.rubocop.yml > ./dot/.rubocop.yml
cp -r -f ~/.zsh ./
