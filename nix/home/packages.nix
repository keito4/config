{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # === Development Tools ===
    git
    gh
    ghq
    deno
    openjdk
    pipenv
    uv
    gcc

    # === Cloud & DevOps ===
    awscli2
    aws-sam-cli
    azure-cli
    kubernetes-helm
    sops
    terraform
    certbot
    nginx

    # === Database & Backend ===
    postgresql_14
    freetds

    # === Utilities ===
    coreutils
    fzf
    peco
    tig
    tree
    trash-cli
    translate-shell
    socat
    inetutils # telnet
    p7zip
    gawk
    gnupg
    terminal-notifier
    zsh-completions

    # === Media & Graphics ===
    ffmpeg
    imagemagick
    graphviz
    poppler

    # === Fun & Misc ===
    cowsay
    figlet
    toilet
    sl

    # === Editors ===
    emacs

    # === Libraries (needed for builds) ===
    openblas
    llvm
  ];

  # fzf integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.jq.enable = true;
}
