# export-vscode:
if [[ $(uname) = "Darwin" ]] then
	code --list-extensions > ./vscode/extensions.txt
	cat ~/Library/Application\ Support/Code/User/settings.json > ./vscode/settings.json
	cat ~/Library/Application\ Support/Code/User/keybindings.json > ./vscode/keybindings.json
fi

# export-brew:
if [[ $(uname) = "Linux" ]] then
	brew bundle dump --file ./brew/LinuxBrewfile --force --all
else
	brew bundle dump --file ./brew/MacOSBrewfile --force --all
fi

# export-git:
cat ~/.git/gitconfig > ./git/gitconfig
cat ~/.git/gitignore > ./git/gitignore
cat ~/.git/gitattributes > ./git/gitattributes

# export-sh:
cat ~/.zprofile > ./dot/.zprofile
cat ~/.zshrc > ./dot/.zshrc

# export-others:
cat ~/.rubocop.yml > ./dot/.rubocop.yml

# export-zsh:
cp -r -f ~/.zsh ./
