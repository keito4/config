# >>>> kubectl command completion (start)
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
fi
# <<<<  kubectl command completion (end)

# >>>> supabase command completion (start)
if command -v supabase &> /dev/null; then
  source <(supabase completion zsh)
fi
# <<<<  supabase command completion (end)

# >>>> 1password command completion (start)
if command -v op &> /dev/null; then
  eval "$(op completion zsh)"; compdef _op op
fi
# <<<<  1password command completion (end)

# >>>> Vagrant command completion (start)
if [[ -d /opt/vagrant/embedded/gems/2.3.0/gems/vagrant-2.3.0/contrib/zsh ]]; then
  fpath=(/opt/vagrant/embedded/gems/2.3.0/gems/vagrant-2.3.0/contrib/zsh $fpath)
  compinit
fi
# <<<<  Vagrant command completion (end)

# >>>> nvm command completion (start)
if command -v brew &> /dev/null; then
  [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
fi
# <<<<  nvm command completion (end)

if command -v supabase &> /dev/null; then
  eval "$(supabase completion zsh)"
fi
