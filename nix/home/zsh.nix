{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    sessionVariables = {
      PNPM_HOME = "$HOME/Library/pnpm";
      SUPABASE_UPDATE_CHECK = "false";
    };

    initContent = ''
      # pnpm
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac

      # Rancher Desktop
      [[ -d "$HOME/.rd/bin" ]] && export PATH="$HOME/.rd/bin:$PATH"

      # LM Studio CLI
      [[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

      # OrbStack
      [[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null

      # Kiro CLI
      [[ -f "''${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "''${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
      [[ "$TERM_PROGRAM" == "kiro" ]] && [[ -x "$(command -v kiro)" ]] && . "$(kiro --locate-shell-integration-path zsh)"
      [[ -f "''${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "''${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

      # Custom functions
      if [[ -d "$HOME/.zsh/functions" ]]; then
        for function in "$HOME"/.zsh/functions/*; do
          source "$function"
        done
      fi

      # Custom configs (pre -> main -> post)
      _load_settings() {
        _dir="$1"
        if [[ -d "$_dir" ]]; then
          if [[ -d "$_dir/pre" ]]; then
            for config in "$_dir"/pre/*(N-.); do
              . "$config"
            done
          fi
          for config in "$_dir"/**/*(N-.); do
            case "$config" in
              "$_dir"/(pre|post)/*|*.zwc) ;;
              *) . "$config" ;;
            esac
          done
          if [[ -d "$_dir/post" ]]; then
            for config in "$_dir"/post/*; do
              . "$config"
            done
          fi
        fi
      }
      _load_settings "$HOME/.zsh/configs"
    '';

    shellAliases = {
      # ni - package manager command unifier (@antfu/ni)
      nrd = "nr dev";
      nrb = "nr build";
      nrs = "nr start";
      nrp = "nr preview";

      # Nix shortcuts
      nix-switch = "darwin-rebuild switch --flake ~/develop/github.com/keito4/config/nix";
      nix-update = "cd ~/develop/github.com/keito4/config/nix && nix flake update";
    };
  };

  # zsh config files managed by home-manager (startup optimization)
  home.file = {
    ".zsh/configs/pre/completion.zsh" = {
      text = ''
        # Vagrant (compinit より前に fpath へ追加する必要がある)
        for _vagrant_comp_dir in /opt/vagrant/embedded/gems/*/gems/vagrant-*/contrib/zsh(/N); do
          fpath=("$_vagrant_comp_dir" $fpath)
          break
        done
        unset _vagrant_comp_dir

        # compinit: use cache within 24h, full security check once per day
        autoload -Uz compinit
        if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
          compinit -d $HOME/.zcompdump;
        else
          compinit -C -d $HOME/.zcompdump;
        fi;
      '';
    };

    ".zsh/configs/virtual/node.zsh" = {
      text = ''
        export NVM_DIR="$HOME/.nvm"

        # nvm lazy load: node/npm/npx/nvm 初回実行時にロード (~700ms 短縮)
        _nvm_lazy_load() {
          unset -f nvm node npm npx
          local brew_prefix="''${HOMEBREW_PREFIX:-/opt/homebrew}"
          local nvm_sh="$brew_prefix/opt/nvm/nvm.sh"
          local nvm_comp="$brew_prefix/opt/nvm/etc/bash_completion.d/nvm"
          if [ -s "$nvm_sh" ]; then
            \. "$nvm_sh"
            [ -s "$nvm_comp" ] && \. "$nvm_comp"
          elif [ -s "''${NVM_DIR}/nvm.sh" ]; then
            # フォールバック: 非Homebrew インストール ($NVM_DIR) を使用
            \. "''${NVM_DIR}/nvm.sh"
          else
            echo "nvm: nvm.sh not found (checked: $nvm_sh, ''${NVM_DIR}/nvm.sh)" >&2
            return 1
          fi
        }
        nvm()  { _nvm_lazy_load; nvm "$@"; }
        node() { _nvm_lazy_load; node "$@"; }
        npm()  { _nvm_lazy_load; npm "$@"; }
        npx()  { _nvm_lazy_load; npx "$@"; }
      '';
    };

    ".zsh/configs/completion.zsh" = {
      text = ''
        # 補完の遅延読み込み: 各コマンド初回 Tab 時にロード

        # kubectl
        if (( $+commands[kubectl] )); then
          function _lazy_kubectl_completion() {
            unfunction _lazy_kubectl_completion
            source <(kubectl completion zsh)
            compdef _kubectl kubectl
            _kubectl "$@"
          }
          compdef _lazy_kubectl_completion kubectl
        fi

        # supabase
        if (( $+commands[supabase] )); then
          function _lazy_supabase_completion() {
            unfunction _lazy_supabase_completion
            source <(supabase completion zsh)
            compdef _supabase supabase
            _supabase "$@"
          }
          compdef _lazy_supabase_completion supabase
        fi

        # 1password
        if (( $+commands[op] )); then
          function _lazy_op_completion() {
            unfunction _lazy_op_completion
            eval "$(op completion zsh)"
            compdef _op op
            _op "$@"
          }
          compdef _lazy_op_completion op
        fi

        # nvm completion は node.zsh の遅延読み込み時に処理
      '';
    };
  };

  # direnv for per-project Nix shells
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
