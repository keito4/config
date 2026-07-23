{
  pkgs,
  username,
  determinateNix,
  ...
}:

{
  imports = [
    ../../modules/kanary.nix
    ../../modules/homebrew.nix
  ];

  # Nix settings
  # Determinate Nix 環境では nix-darwin による Nix 管理を無効化する
  # （experimental-features や GC は Determinate 側が管理）
  nix =
    if determinateNix then
      {
        enable = false;
      }
    else
      {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          # Trusted users for remote builds
          trusted-users = [
            "root"
            username
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
    primaryUser = username;

    defaults = {
      # Dock
      dock = {
        autohide = true;
        show-recents = false;
        mru-spaces = false;
        persistent-apps = [ ];
        persistent-others = [ ];
      };
      # Menu bar
      controlcenter = {
        AirDrop = false;
        BatteryShowPercentage = true;
        Bluetooth = false;
        Display = false;
        FocusModes = false;
        NowPlaying = false;
        Sound = false;
      };
      menuExtraClock = {
        Show24Hour = true;
        ShowAMPM = false;
        ShowDate = 1;
        ShowDayOfMonth = true;
        ShowDayOfWeek = true;
        ShowSeconds = false;
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
        "com.jordanbaird.Ice" = {
          AutoRehide = true;
          EnableAlwaysHiddenSection = false;
          HideApplicationMenus = true;
          ShowIceIcon = true;
          ShowOnClick = true;
          ShowOnHover = false;
          ShowOnScroll = true;
          ShowSectionDividers = false;
          UseIceBar = false;
        };
        "com.apple.Spotlight" = {
          "NSStatusItem VisibleCC Item-0" = false;
        };
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

  launchd.user.agents = {
    bettertouchtool = {
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-g"
          "-a"
          "BetterTouchTool"
        ];
        RunAtLoad = true;
      };
    };
    ice = {
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-g"
          "-a"
          "Ice"
        ];
        RunAtLoad = true;
      };
    };
    raycast = {
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-g"
          "-a"
          "Raycast"
        ];
        RunAtLoad = true;
      };
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Security
  security.pam.services.sudo_local.touchIdAuth = true;

  services.skhd = {
    enable = true;
    skhdConfig = ''
      ctrl + shift - j    : /Users/${username}/.local/bin/send-ime-key kana
      ctrl + shift - 0x29 : /Users/${username}/.local/bin/send-ime-key eisuu
    '';
  };

  # Agent Deck Web UI (headless) — http://127.0.0.1:8420
  # loopback バインドのみ。外部公開する場合は tailscale serve を経由させること
  launchd.user.agents.agent-deck-web = {
    serviceConfig = {
      ProgramArguments = [
        "/opt/homebrew/bin/agent-deck"
        "web"
        "--no-tui"
        "--listen"
        "127.0.0.1:8420"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${username}/Library/Logs/agent-deck-web.log";
      StandardErrorPath = "/Users/${username}/Library/Logs/agent-deck-web.err.log";
      EnvironmentVariables = {
        # claude/codex (~/.local/bin, ~/.bin)・node/gh (nix profile)・agent-deck (homebrew) を解決できる PATH
        PATH = "/Users/${username}/.local/bin:/Users/${username}/.bin:/opt/homebrew/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin";
      };
    };
  };

  # Shells
  programs.zsh.enable = true;
}
