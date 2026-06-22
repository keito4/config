{ pkgs, ... }:

let
  cmuxSchema = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";

  localBrowserHosts = [
    "localhost"
    "127.0.0.1"
    "::1"
    "0.0.0.0"
    "*.localhost"
    "*.localtest.me"
  ];

  cmuxConfig = {
    "$schema" = cmuxSchema;
    schemaVersion = 1;

    app = {
      confirmQuit = "dirty-only";
      newWorkspacePlacement = "afterCurrent";
      openMarkdownInCmuxViewer = true;
      openSupportedFilesInCmux = true;
      reorderOnNotification = true;
      workspaceInheritWorkingDirectory = true;
    };

    automation = {
      claudeCodeIntegration = true;
      ripgrepBinaryPath = "${pkgs.ripgrep}/bin/rg";
      socketControlMode = "cmuxOnly";
      suppressSubagentNotifications = true;
    };

    browser = {
      defaultSearchEngine = "google";
      hostsToOpenInEmbeddedBrowser = localBrowserHosts;
      insecureHttpHostsAllowedInEmbeddedBrowser = localBrowserHosts;
      openTerminalLinksInCmuxBrowser = false;
    };

    notifications = {
      dockBadge = true;
      paneFlash = true;
      showInMenuBar = true;
      unreadPaneRing = true;
    };

    sidebar = {
      openPortLinksInCmuxBrowser = true;
      openPullRequestLinksInCmuxBrowser = true;
      showBranchDirectory = true;
      showCustomMetadata = true;
      showLog = true;
      showNotificationMessage = true;
      showPorts = true;
      showProgress = true;
      showPullRequests = true;
      showSSH = true;
    };

    terminal = {
      autoResumeAgentSessions = true;
      copyOnSelect = true;
      focusTextBoxOnNewTerminals = false;
      showScrollBar = false;
      showTextBoxOnNewTerminals = false;
    };
  };

  ghosttyConfig = ''
    font-family = SF Mono
    font-size = 13
    sidebar-font-size = 14
    surface-tab-bar-font-size = 11
    scrollback-limit = 50000000
    split-divider-color = #3e4451
  '';
in
{
  home.file.".config/cmux/config" = {
    force = true;
    text = "";
  };

  home.file.".config/cmux/cmux.json" = {
    force = true;
    text = builtins.toJSON cmuxConfig + "\n";
  };

  home.file.".config/ghostty/config" = {
    force = true;
    text = ghosttyConfig;
  };
}
