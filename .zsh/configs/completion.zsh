# Lazy-load command completions so heavy CLIs aren't invoked at shell startup.
# (Eager `source <(tool completion zsh)` calls slow startup and surface noisy
# update-check messages, e.g. supabase printing a new-version banner.)
#
# Each stub re-registers the real completion function and immediately calls it,
# so completions appear on the very first Tab instead of requiring a second one.

# kubectl
if (( $+commands[kubectl] )); then
  _lazy_kubectl_completion() {
    unfunction _lazy_kubectl_completion
    source <(kubectl completion zsh)
    compdef _kubectl kubectl
    _kubectl "$@"
  }
  compdef _lazy_kubectl_completion kubectl
fi

# supabase
if (( $+commands[supabase] )); then
  _lazy_supabase_completion() {
    unfunction _lazy_supabase_completion
    source <(SUPABASE_UPDATE_CHECK=false supabase completion zsh 2>/dev/null)
    compdef _supabase supabase
    _supabase "$@"
  }
  compdef _lazy_supabase_completion supabase
fi

# 1password
if (( $+commands[op] )); then
  _lazy_op_completion() {
    unfunction _lazy_op_completion
    eval "$(op completion zsh)"
    compdef _op op
    _op "$@"
  }
  compdef _lazy_op_completion op
fi

# nvm completion は configs/virtual/node.zsh の遅延読み込み時に処理する。
# Vagrant の補完は compinit より前に fpath を延ばす必要があるため
# configs/pre/completion.zsh 側で登録する。
