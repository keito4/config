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

  # direnv for per-project Nix shells
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
