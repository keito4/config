{ pkgs, lib, ... }:

{
  imports = [
    ./packages.nix
    ./git.nix
    ./zsh.nix
    ./dotfiles.nix
    ./agent-commands.nix
    ./input-source.nix
    ./kanary.nix
    ./cmux.nix
  ];

  home = {
    stateVersion = "24.11";
    username = "keito";
    homeDirectory = lib.mkForce "/Users/keito";
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
