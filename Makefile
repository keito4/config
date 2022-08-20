ifeq ($(shell uname), Linux)
	OS=linux
else
	ifeq ($(shell uname), Darwin)
		OS=darwin
	else
		OS=windows
	endif
endif


export: export-vscode export-brew

export-vscode:
	code --list-extensions > extensions_list.txt

export-brew:
	brew bundle dump

import-brew:
	brew bundle
