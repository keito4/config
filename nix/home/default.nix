{ pkgs, lib, ... }:

{
  imports = [
    ./packages.nix
    ./git.nix
    ./zsh.nix
  ];

  home = {
    stateVersion = "24.11";
    username = "keito";
    homeDirectory = lib.mkForce "/Users/keito";
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
