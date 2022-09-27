#! /bin/zsh

if [[ $(uname) = "Linux" ]] then
	OS=linux
else
	if [[ $(uname) = "Darwin" ]] then
		OS=darwin
	else
		OS=windows
	fi
fi

# import-brew:
if [[ $OS = "linux" ]] then
	brew bundle --file ./brew/LinuxBrewfile
else
  if [[ $OS = "darwin" ]] then
  	brew bundle --file ./brew/MacOSBrewfile
  fi
fi

# import-vscode:
if [[ $OS = "linux" ]] then
else
  if [[ $OS = "darwin" ]] then
    cat ./vscode/extensions.txt | xargs -I@ code --install-extension @
    cat ./vscode/settings.json > ~/Library/Application\ Support/Code/User/settings.json
    cat ./vscode/keybindings.json > ~/Library/Application\ Support/Code/User/keybindings.json
  fi
fi

# import-zsh:
# apt install zsh
# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# chsh -s /usr/bin/zsh
cp -r -f .zsh ~
cp ./sh/.zprofile ~/
cp ./sh/.zshrc ~/

# import-git:
cp -r -f ./git ~/.git
