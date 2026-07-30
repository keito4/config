PATH="/usr/bin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="/opt/homebrew/bin:$PATH"

# ensure dotfiles bin directory is loaded first
PATH="$HOME/.bin:/usr/local/sbin:$PATH"

# claude / codex などのネイティブインストーラーは ~/.local/bin に入れる
PATH="$HOME/.local/bin:$PATH"

# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

PATH="/usr/local/opt/mysql@5.7/bin:$PATH"

PATH="$HOME/flutter/bin:$PATH"

export -U PATH
