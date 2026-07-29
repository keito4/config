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

  # skhd: services.skhd は nix store パスのバイナリを launchd に登録するため、
  # skhd 更新のたびに TCC (アクセシビリティ) 許可の再付与が必要になる。
  # activation で /usr/local/bin/skhd に実体コピーした安定パスから起動することで、
  # 許可対象のパスを固定する。
  #
  # ただしパスの固定だけでは足りない。nixpkgs の skhd は ad-hoc (linker-signed)
  # なので TCC は cdhash で許可を紐付けており、コピーの中身が変わると許可が失効する。
  # しかも ad-hoc バイナリは同定が不安定で、システム設定で許可を付け直しても
  # launchd が直接起動したプロセスには適用されない (ターミナルから手動起動した
  # ときだけ親の許可を継承して動く)。
  # そこでコピー後に固定の自己署名 identity で署名し、TCC が designated
  # requirement で紐付けるようにする。identity の作成は管理者認証を伴うため
  # script/macos/setup-skhd-signing.sh を本人が一度実行する。未作成のうちは
  # 署名を飛ばすだけで、従来どおりの動作を壊さない。
  environment.etc."skhdrc".text = ''
    ctrl + shift - j    : /Users/${username}/.local/bin/send-ime-key kana
    ctrl + shift - 0x29 : /Users/${username}/.local/bin/send-ime-key eisuu
  '';

  system.activationScripts.postActivation.text = ''
    skhdSigningIdentity=skhd-local-signing

    # 署名済みのコピーは中身が元バイナリと一致しないため、cmp ではなく
    # 「元バイナリと同じ内容から作られた署名か」を cdhash 相当で判定できない。
    # ここでは元バイナリのハッシュを控えておき、それが変わったときだけ入れ替える。
    skhdStampFile=/usr/local/bin/.skhd.nix-source-hash
    skhdWant=$(/usr/bin/shasum -a 256 "${pkgs.skhd}/bin/skhd" | cut -d' ' -f1)
    skhdHave=$(cat "$skhdStampFile" 2>/dev/null || echo none)

    if [ "$skhdWant" != "$skhdHave" ] || [ ! -x /usr/local/bin/skhd ]; then
      mkdir -p /usr/local/bin
      install -m 755 "${pkgs.skhd}/bin/skhd" /usr/local/bin/skhd
      echo "installed skhd to /usr/local/bin/skhd"

      if /usr/bin/security find-identity -v -p codesigning /Library/Keychains/System.keychain 2>/dev/null | grep -q "$skhdSigningIdentity"; then
        /usr/bin/codesign --force --sign "$skhdSigningIdentity" --identifier org.nixos.skhd --timestamp=none /usr/local/bin/skhd
        echo "signed skhd with $skhdSigningIdentity"
      else
        echo "skhd: signing identity '$skhdSigningIdentity' not found; run script/macos/setup-skhd-signing.sh to keep the accessibility grant across updates"
      fi

      printf '%s\n' "$skhdWant" > "$skhdStampFile"
    fi
  '';

  launchd.user.agents.skhd = {
    serviceConfig = {
      ProgramArguments = [
        "/usr/local/bin/skhd"
        "-c"
        "/etc/skhdrc"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
    };
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
