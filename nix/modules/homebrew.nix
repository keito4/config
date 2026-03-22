{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap"; # Remove unlisted packages
    };

    # === Taps ===
    taps = [
      "1password/tap"
      "koekeishiya/formulae"
      "nikitabobko/tap"
      "supabase/tap"
      "ynqa/tap"
      "yukiarrr/tap"
    ];

    # === Formulae (Nix にないもの / tap 依存 / macOS 固有) ===
    brews = [
      "cliclick" # macOS automation
      "mas" # Mac App Store CLI
      "pinentry-mac" # GPG pinentry for macOS

      # Tap-dependent formulae
      "koekeishiya/formulae/skhd"
      "koekeishiya/formulae/yabai"
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
      "cursor"
      "dotnet-sdk"
      "gcloud-cli"
      "ngrok"
      "orbstack"
      "rancher"
      "tableplus"
      "visual-studio-code"

      # Communication
      "discord"
      "messenger"
      "slack"
      "zoom"

      # Productivity
      "aerospace"
      "alfred"
      "bartender"
      "bettertouchtool"
      "karabiner-elements"
      "notion"
      "notion-calendar"
      "raycast"

      # AI Tools
      "chatgpt"
      "claude"

      # Browsers
      "arc"

      # Utilities
      "appcleaner"
      "blackhole-2ch"
      "calibre"
      "deepl"
      "dropbox"
      "google-japanese-ime"
      "parallels-client"
      "qblocker"
      "the-unarchiver"

      # Network
      "tailscale-app"
    ];

    # === Mac App Store ===
    masApps = {
      "Keynote" = 409183694;
      "LINE" = 539883307;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Paste" = 967805235;
      "Prime Video" = 545519333;
      "Windows App" = 1295203466;
      "Xcode" = 497799835;
    };
  };
}
