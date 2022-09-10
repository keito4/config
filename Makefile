ifeq ($(shell uname), Linux)
	OS=linux
else
	ifeq ($(shell uname), Darwin)
		OS=darwin
	else
		OS=windows
	endif
endif


export: export-vscode export-brew export-git export-sh export-zsh

export-vscode:
	code --list-extensions > ./vscode/extensions.txt
	cat ~/Library/Application\ Support/Code/User/settings.json > ./vscode/settings.json
	cat ~/Library/Application\ Support/Code/User/keybindings.json > ./vscode/keybindings.json

export-brew:
	brew bundle dump --file ./macOS/Brewfile --force --all

export-git:
	cat ~/.gitconfig > ./git/gitconfig
	cat ~/.gitignore > ./git/gitignore
	cat ~/.gitattributes > ./git/gitattributes

export-sh:
	cat ~/.zprofile > ./sh/.zprofile
	cat ~/.zshrc > ./sh/.zshrc

export-zsh:
	cp -r -f ~/.zsh ./

import-brew:
	brew bundle --file ./macOS/Brewfile

import-vscode:
	cat ./vscode/extensions.txt | xargs -I@ code --install-extension @
	# cat ./vscode/extensions.txt | xargs -I@ code-server --install-extension @
	cat ./vscode/settings.json > ~/Library/Application\ Support/Code/User/settings.json
	cat ./vscode/keybindings.json > ~/Library/Application\ Support/Code/User/keybindings.json

import-zsh:
	cp -r -f ./zsh ~/.zsh/
