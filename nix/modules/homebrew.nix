{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none"; # Keep user-installed apps outside this config.
    };

    # === Taps ===
    taps = [
      "1password/tap"
      "asheshgoplani/tap"
      "koekeishiya/formulae"
      "nikitabobko/tap"
      "supabase/tap"
      "ynqa/tap"
      "yukiarrr/tap"
    ];

    # === Formulae (Nix にないもの / tap 依存 / macOS 固有) ===
    brews = [
      "asheshgoplani/tap/agent-deck" # Agent Deck CLI
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
      "android-studio"
      "cursor"
      "dotnet-sdk"
      "elgato-stream-deck"
      "flutter"
      "gcloud-cli"
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
