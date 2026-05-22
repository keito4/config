# Lazy-load command completions so heavy CLIs aren't invoked at shell startup.
# (Eager `source <(tool completion zsh)` calls slow startup and surface noisy
# update-check messages, e.g. supabase printing a new-version banner.)

# kubectl
if (( $+commands[kubectl] )); then
  _lazy_kubectl_completion() {
    unfunction _lazy_kubectl_completion
    source <(kubectl completion zsh)
  }
  compdef _lazy_kubectl_completion kubectl
fi

# supabase
if (( $+commands[supabase] )); then
  _lazy_supabase_completion() {
    unfunction _lazy_supabase_completion
    source <(SUPABASE_UPDATE_CHECK=false supabase completion zsh 2>/dev/null)
  }
  compdef _lazy_supabase_completion supabase
fi

# 1password
if (( $+commands[op] )); then
  _lazy_op_completion() {
    unfunction _lazy_op_completion
    eval "$(op completion zsh)"
    compdef _op op
  }
  compdef _lazy_op_completion op
fi

# Vagrant (must extend fpath before compinit; only when installed)
for _vagrant_comp_dir in /opt/vagrant/embedded/gems/*/gems/vagrant-*/contrib/zsh(/N); do
  fpath=("$_vagrant_comp_dir" $fpath)
  break
done
unset _vagrant_comp_dir

# nvm
if command -v brew >/dev/null 2>&1; then
  _nvm_comp="$(brew --prefix 2>/dev/null)/opt/nvm/etc/bash_completion.d/nvm"
  [[ -s "$_nvm_comp" ]] && \. "$_nvm_comp"
  unset _nvm_comp
fi
