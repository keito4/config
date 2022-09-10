PATH="/usr/bin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="/opt/homebrew/bin:$PATH"

# ensure dotfiles bin directory is loaded first
PATH="$HOME/.bin:/usr/local/sbin:$PATH"

# Try loading ASDF from the regular home dir location
PATH="$HOME/.cargo/bin:$PATH"

# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

PATH="/usr/local/opt/mysql@5.7/bin:$PATH"

PATH="/opt/homebrew/opt/php@7.4/bin:$PATH"
PATH="/opt/homebrew/opt/php@7.4/sbin:$PATH"

export -U PATH
