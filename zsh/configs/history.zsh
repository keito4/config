setopt hist_ignore_all_dups inc_append_history
HISTFILE=~/.zhistory
HISTSIZE=100000
SAVEHIST=100000

export ERL_AFLAGS="-kernel shell_history enabled"
