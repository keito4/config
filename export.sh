# export-vscode:
# 	code --list-extensions > ./vscode/extensions.txt
# 	cat ~/Library/Application\ Support/Code/User/settings.json > ./vscode/settings.json
# 	cat ~/Library/Application\ Support/Code/User/keybindings.json > ./vscode/keybindings.json

# export-brew:
if [[ $(uname) = "Linux" ]] then
	brew bundle dump --file ./brew/LinuxBrewfile --force --all
else
	brew bundle dump --file ./brew/MacOSBrewfile --force --all
fi

# export-git:
cat ~/.gitconfig > ./git/gitconfig
cat ~/.gitignore > ./git/gitignore
cat ~/.gitattributes > ./git/gitattributes

# export-sh:
cat ~/.zprofile > ./sh/.zprofile
cat ~/.zshrc > ./sh/.zshrc

# export-zsh:
cp -r -f ~/.zsh ./
