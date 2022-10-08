# >>>> kubectl command completion (start)
source <(kubectl completion zsh)
# <<<<  kubectl command completion (end)


# >>>> 1password command completion (start)
eval "$(op completion zsh)"; compdef _op op
# <<<<  1password command completion (end)

# >>>> Vagrant command completion (start)
fpath=(/opt/vagrant/embedded/gems/2.3.0/gems/vagrant-2.3.0/contrib/zsh $fpath)
compinit
# <<<<  Vagrant command completion (end)

# >>>> nvm command completion (start)
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
# <<<<  nvm command completion (end)
