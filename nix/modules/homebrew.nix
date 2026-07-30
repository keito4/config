{ config, lib, ... }:

let
  # brew trust（Homebrew 6+）にも渡すため let で束ねる
  taps = [
    "1password/tap"
    "asheshgoplani/tap"
    "koekeishiya/formulae"
    "nikitabobko/tap"
    "supabase/tap"
    "ynqa/tap"
    "yukiarrr/tap"
  ];
in
{
  # Homebrew 6+ はサードパーティ tap を明示的に信頼しないと formula/cask を
  # 読み込まない（新規マシンで brew bundle が失敗する）。trust.json は
  # ユーザー単位の設定なので primaryUser として事前に登録する。
  system.activationScripts.preActivation.text = ''
    if [ -x /opt/homebrew/bin/brew ] && sudo -u ${config.system.primaryUser} -H /opt/homebrew/bin/brew trust --help >/dev/null 2>&1; then
      ${lib.concatMapStringsSep "\n    " (
        tap: ''sudo -u ${config.system.primaryUser} -H /opt/homebrew/bin/brew trust "${tap}" || true''
      ) taps}
    fi
  '';

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none"; # Keep user-installed apps outside this config.
    };

    # === Taps ===
    inherit taps;

    # === Formulae (Nix にないもの / tap 依存 / macOS 固有) ===
    brews = [
      "asheshgoplani/tap/agent-deck" # Agent Deck CLI
      "bash" # bash 4+ (setup-claude.sh や typeset -g を使うスクリプトが必要。macOS 標準は 3.2)
      "cliclick" # macOS automation
      "mas" # Mac App Store CLI
      "pinentry-mac" # GPG pinentry for macOS

      # Tap-dependent formulae
      "koekeishiya/formulae/skhd"
      "supabase/tap/supabase"
      "ynqa/tap/jnv"
      "yukiarrr/tap/ecsk"
    ];

    # === Casks (GUI Applications) ===
    casks = [
      # Security & Privacy
      "1password"
      "1password-cli"

      # Development Tools
      # gcloud は nixpkgs の google-cloud-sdk で管理（cask の postinstall が
      # virtualenv コマンドを要求し、新規マシンで失敗するため）
      "android-studio"
      "cursor"
      "dotnet-sdk"
      "elgato-stream-deck"
      "flutter"
      "ngrok"
      "orbstack"
      "tableplus"
      "visual-studio-code"

      # Communication
      "discord"
      "slack"
      "zoom"

      # Productivity
      "aerospace"
      "bettertouchtool"
      "duet"
      "linear"
      "notion"
      "notion-calendar"
      "raycast"
      "readdle-spark"

      # AI Tools
      "chatgpt"
      "claude"
      "cmux"
      "typeless" # AI voice dictation

      # Browsers
      "arc"
      "google-chrome"

      # Utilities
      "appcleaner"
      "blackhole-2ch"
      "calibre"
      "deepl"
      "dropbox"
      "google-japanese-ime"
      "jordanbaird-ice"
      "parallels-client"
      "qblocker"
      "the-unarchiver"

      # Network
      "tailscale-app"
    ];

    # === Mac App Store ===
    masApps = {
      "Keynote" = 361285480;
      "LINE" = 539883307;
      "Paste" = 967805235;
      "Windows App" = 1295203466;
      "Xcode" = 497799835;
    };
  };
}
