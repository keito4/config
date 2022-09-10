alias ll='ls -al'
alias ln='ln -v'
alias e='$EDITOR'
alias dock='defaults write com.apple.Dock autohide-delay -float 10; killall Dock'
# alias rm='trash'
alias rmdir='rm -rf'
alias his='history 20'
alias psg='ps ax | grep'

# Bundler
alias be='bundle exec'

# Rails
alias migrate='rake db:migrate db:rollback && rake db:migrate db:test:prepare'
alias s='rspec'

# Pretty print the path
alias path='echo $PATH | tr -s ":" "\n"'

# tig
alias s='tig status'
alias t='tig'

# git
alias gpom='git pull origin master'
alias gdh='git diff HEAD^'
alias gds='git diff --stat'


# Include custom aliases
if [[ -f ~/.aliases.local ]]; then
  source ~/.aliases.local
fi

alias ..='cd ../'
alias ...='cd ../..'
alias ....='cd ../../..'
