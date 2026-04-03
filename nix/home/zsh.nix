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
        # completion; use cache unconditionally for fast startup
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

        # デフォルト Node.js の PATH を即座に設定（claude 等の shebang 用）
        # nvm 本体の初期化のみ遅延させる
        if [ -d "$NVM_DIR/versions/node" ]; then
          NODE_DEFAULT_DIR="$NVM_DIR/alias/default"
          if [ -L "$NODE_DEFAULT_DIR" ] || [ -f "$NODE_DEFAULT_DIR" ]; then
            NODE_VER=$(cat "$NODE_DEFAULT_DIR" 2>/dev/null)
            NODE_BIN="$NVM_DIR/versions/node/v''${NODE_VER#v}/bin"
          else
            # default alias がなければ最新バージョンを使用
            NODE_BIN=$(ls -d "$NVM_DIR/versions/node"/*/bin 2>/dev/null | sort -V | tail -1)
          fi
          [ -d "$NODE_BIN" ] && export PATH="$NODE_BIN:$PATH"
        fi

        # nvm 本体の遅延読み込み（nvm コマンド初回実行時のみ）
        _nvm_lazy_load() {
          unset -f nvm
          local brew_prefix="''${HOMEBREW_PREFIX:-/opt/homebrew}"
          local nvm_sh="$brew_prefix/opt/nvm/nvm.sh"
          local nvm_comp="$brew_prefix/opt/nvm/etc/bash_completion.d/nvm"
          [ -s "$nvm_sh" ] && \. "$nvm_sh"
          [ -s "$nvm_comp" ] && \. "$nvm_comp"
        }
        nvm() { _nvm_lazy_load; nvm "$@"; }

        export PNPM_HOME="$HOME/Library/pnpm"
        case ":$PATH:" in
          *":$PNPM_HOME:"*) ;;
          *) export PATH="$PNPM_HOME:$PATH" ;;
        esac
      '';
    };

    ".zsh/configs/completion.zsh" = {
      text = ''
        # 補完の遅延読み込み: 各コマンド初回 Tab 時にロード

        # kubectl
        if (( $+commands[kubectl] )); then
          function _lazy_kubectl_completion() {
            source <(kubectl completion zsh)
            compdef _kubectl kubectl
          }
          compdef _lazy_kubectl_completion kubectl
        fi

        # supabase
        if (( $+commands[supabase] )); then
          function _lazy_supabase_completion() {
            source <(supabase completion zsh)
            compdef _supabase supabase
          }
          compdef _lazy_supabase_completion supabase
        fi

        # 1password
        if (( $+commands[op] )); then
          function _lazy_op_completion() {
            eval "$(op completion zsh)"
            compdef _op op
          }
          compdef _lazy_op_completion op
        fi

        # Vagrant
        if [ -d /opt/vagrant/embedded/gems/2.3.0/gems/vagrant-2.3.0/contrib/zsh ]; then
          fpath=(/opt/vagrant/embedded/gems/2.3.0/gems/vagrant-2.3.0/contrib/zsh $fpath)
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
