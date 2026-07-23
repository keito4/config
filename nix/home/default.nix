{
  pkgs,
  lib,
  username,
  ...
}:

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
    inherit username;
    homeDirectory = lib.mkForce "/Users/${username}";
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
