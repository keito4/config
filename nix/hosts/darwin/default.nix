{ pkgs, ... }:

{
  imports = [
    ../../modules/kanary.nix
    ../../modules/homebrew.nix
  ];

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Trusted users for remote builds
      trusted-users = [
        "root"
        "keito"
      ];
    };
    # Garbage collection
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
  };

  # System packages (available to all users)
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
  ];

  # macOS system preferences
  system = {
    # nix-darwin state version
    stateVersion = 6;

    # Primary user (required for homebrew, system.defaults, etc.)
    primaryUser = "keito";

    defaults = {
      # Dock
      dock = {
        autohide = true;
        show-recents = false;
        mru-spaces = false;
        persistent-apps = [
          "/Applications/Google Chrome.app"
          "/Applications/Arc.app"
          "/Applications/Cursor.app"
          "/Applications/Visual Studio Code.app"
          "/Applications/Codex.app"
          "/Applications/cmux.app"
          "/System/Applications/Utilities/Terminal.app"
          "/Applications/Slack.app"
          "/Applications/1Password.app"
          "/Applications/Raycast.app"
        ];
        persistent-others = [ ];
      };
      # Finder
      finder = {
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "Nlsv"; # List view
      };
      # Global
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      CustomUserPreferences = {
        "com.apple.HIToolbox" = {
          AppleEnabledInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = 252;
              "KeyboardLayout Name" = "ABC";
            }
            {
              "Bundle ID" = "com.google.inputmethod.Japanese";
              InputSourceKind = "Keyboard Input Method";
            }
            {
              "Bundle ID" = "com.google.inputmethod.Japanese";
              "Input Mode" = "com.google.inputmethod.Japanese.base";
              InputSourceKind = "Input Mode";
            }
            {
              "Bundle ID" = "com.google.inputmethod.Japanese";
              "Input Mode" = "com.google.inputmethod.Japanese.Roman";
              InputSourceKind = "Input Mode";
            }
            {
              "Bundle ID" = "com.apple.CharacterPaletteIM";
              InputSourceKind = "Non Keyboard Input Method";
            }
            {
              "Bundle ID" = "com.apple.50onPaletteIM";
              InputSourceKind = "Non Keyboard Input Method";
            }
          ];
          AppleSelectedInputSources = [
            {
              "Bundle ID" = "com.google.inputmethod.Japanese";
              "Input Mode" = "com.google.inputmethod.Japanese.base";
              InputSourceKind = "Input Mode";
            }
          ];
        };
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Security
  security.pam.services.sudo_local.touchIdAuth = true;

  services.skhd = {
    enable = true;
    skhdConfig = ''
      ctrl + shift - j    : /Users/keito/.local/bin/select-input-source com.google.inputmethod.Japanese.base
      ctrl + shift - 0x29 : /Users/keito/.local/bin/select-input-source com.google.inputmethod.Japanese.Roman
    '';
  };

  # Shells
  programs.zsh.enable = true;
}
