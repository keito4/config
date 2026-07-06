const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('nix-darwin and home-manager macOS configuration', () => {
  test('nix-darwin imports Kanary and Homebrew modules', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('../../modules/kanary.nix');
    expect(darwinHost).toContain('../../modules/homebrew.nix');
    expect(darwinHost).not.toContain('karabiner');
    expect(darwinHost).toContain('enableKeyMapping = true;');
    expect(darwinHost).toContain('remapCapsLockToControl = true;');
  });

  test('Google Japanese Input sources include hiragana and alphanumeric modes', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('"com.apple.HIToolbox"');
    expect(darwinHost).toContain('AppleEnabledInputSources');
    expect(darwinHost).toContain('com.google.inputmethod.Japanese.base');
    expect(darwinHost).toContain('com.google.inputmethod.Japanese.Roman');
  });

  test('Dock shows running apps without pinned or recent apps', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('dock = {');
    expect(darwinHost).toContain('show-recents = false;');
    expect(darwinHost).toContain('persistent-apps = [ ];');
    expect(darwinHost).toContain('persistent-others = [ ];');
    expect(darwinHost).not.toContain('"/Applications/Google Chrome.app"');
    expect(darwinHost).not.toContain('"/Applications/Raycast.app"');
  });

  test('menu bar keeps only work-essential system controls visible', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('controlcenter = {');
    expect(darwinHost).toContain('BatteryShowPercentage = true;');
    expect(darwinHost).toContain('AirDrop = false;');
    expect(darwinHost).toContain('Bluetooth = false;');
    expect(darwinHost).toContain('Display = false;');
    expect(darwinHost).toContain('FocusModes = false;');
    expect(darwinHost).toContain('NowPlaying = false;');
    expect(darwinHost).toContain('Sound = false;');

    expect(darwinHost).toContain('menuExtraClock = {');
    expect(darwinHost).toContain('Show24Hour = true;');
    expect(darwinHost).toContain('ShowAMPM = false;');
    expect(darwinHost).toContain('ShowDate = 1;');
    expect(darwinHost).toContain('ShowDayOfMonth = true;');
    expect(darwinHost).toContain('ShowDayOfWeek = true;');
    expect(darwinHost).toContain('ShowSeconds = false;');
  });

  test('home-manager imports cmux and input source helpers without Karabiner', () => {
    const homeDefault = readRepoFile('nix/home/default.nix');

    expect(homeDefault).toContain('./dotfiles.nix');
    expect(homeDefault).toContain('./agent-commands.nix');
    expect(homeDefault).toContain('./input-source.nix');
    expect(homeDefault).toContain('./cmux.nix');
    expect(homeDefault).not.toContain('./tmux.nix');
    expect(homeDefault).not.toContain('./karabiner.nix');
  });

  test('Homebrew casks install cmux and input tooling', () => {
    const homebrewModule = readRepoFile('nix/modules/homebrew.nix');

    expect(homebrewModule).toContain('"android-studio"');
    expect(homebrewModule).toContain('"asheshgoplani/tap/agent-deck"');
    expect(homebrewModule).toContain('"cmux"');
    expect(homebrewModule).toContain('"elgato-stream-deck"');
    expect(homebrewModule).toContain('"flutter"');
    expect(homebrewModule).toContain('"google-chrome"');
    expect(homebrewModule).toContain('"google-japanese-ime"');
    expect(homebrewModule).not.toContain('"mattermost"');
    expect(homebrewModule).not.toContain('"messenger"');
    expect(homebrewModule).not.toContain('"karabiner-elements"');
    expect(homebrewModule).not.toContain('"bartender"');
    expect(homebrewModule).not.toContain('"rancher"');
    expect(homebrewModule).not.toContain('"google-cloud-sdk"');
    expect(homebrewModule).not.toContain('"tailscale"');
  });

  test('skhd binds IME shortcuts without Karabiner', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('services.skhd = {');
    expect(darwinHost).toContain('enable = true;');
    expect(darwinHost).toContain('ctrl + shift - j');
    expect(darwinHost).toContain('ctrl + shift - 0x29');
    expect(darwinHost).toContain('/Users/keito/.local/bin/select-input-source');
    expect(darwinHost).toContain('com.google.inputmethod.Japanese.base');
    expect(darwinHost).toContain('com.google.inputmethod.Japanese.Roman');
  });

  test('cmux terminal config leaves IME shortcuts to skhd', () => {
    const cmuxModule = readRepoFile('nix/home/cmux.nix');

    expect(cmuxModule).toContain('home.file.".config/cmux/config"');
    expect(cmuxModule).toContain('force = true;');
    expect(cmuxModule).toContain('text = "";');
    expect(cmuxModule).not.toContain('keybind = ctrl+shift+j');
    expect(cmuxModule).not.toContain('keybind = ctrl+shift+semicolon');
    expect(cmuxModule).not.toContain('C-j');
    expect(cmuxModule).not.toContain('C-Semicolon');
  });

  test('cmux app config manages agent-friendly defaults', () => {
    const cmuxModule = readRepoFile('nix/home/cmux.nix');

    expect(cmuxModule).toContain('home.file.".config/cmux/cmux.json"');
    expect(cmuxModule).toContain('"$schema" = cmuxSchema;');
    expect(cmuxModule).toContain('confirmQuit = "dirty-only";');
    expect(cmuxModule).toContain('workspaceInheritWorkingDirectory = true;');
    expect(cmuxModule).toContain('socketControlMode = "automation";');
    expect(cmuxModule).toContain('suppressSubagentNotifications = true;');
    expect(cmuxModule).toContain('ripgrepBinaryPath = "${pkgs.ripgrep}/bin/rg";');
    expect(cmuxModule).toContain('hostsToOpenInEmbeddedBrowser = localBrowserHosts;');
    expect(cmuxModule).toContain('openTerminalLinksInCmuxBrowser = false;');
    expect(cmuxModule).toContain('showPullRequests = true;');
    expect(cmuxModule).toContain('autoResumeAgentSessions = true;');
    expect(cmuxModule).toContain('copyOnSelect = true;');
  });

  test('Ghostty config is managed for cmux terminal rendering', () => {
    const cmuxModule = readRepoFile('nix/home/cmux.nix');

    expect(cmuxModule).toContain('home.file.".config/ghostty/config"');
    expect(cmuxModule).toContain('font-family = SF Mono');
    expect(cmuxModule).toContain('font-size = 13');
    expect(cmuxModule).toContain('sidebar-font-size = 14');
    expect(cmuxModule).toContain('surface-tab-bar-font-size = 11');
    expect(cmuxModule).toContain('scrollback-limit = 50000000');
    expect(cmuxModule).toContain('split-divider-color = #3e4451');
  });

  test('input source helper exposes macOS input source selection commands', () => {
    const inputSourceModule = readRepoFile('nix/home/input-source.nix');
    const inputSourceWrapper = readRepoFile('script/macos/agent-select-input-source.sh');
    const inputSourceSwift = readRepoFile('script/macos/select-input-source.swift');

    expect(fs.existsSync(path.join(repoPath, 'nix/home/tmux.nix'))).toBe(false);
    expect(inputSourceModule).toContain('".local/share/input-source/select-input-source.swift"');
    expect(inputSourceModule).toContain('".local/bin/select-input-source"');
    expect(inputSourceModule).toContain('".local/bin/agent-select-input-source"');
    expect(inputSourceWrapper).toContain('XDG_DATA_HOME');
    expect(inputSourceWrapper).toContain('/input-source/select-input-source.swift');
    expect(inputSourceWrapper).not.toContain('.config/karabiner');
    expect(inputSourceSwift).toContain('TISSelectInputSource(source)');
    expect(inputSourceSwift).not.toContain('TISEnableInputSource');
  });

  test('keyboard remapping is documented through Kanary without home-manager Karabiner state', () => {
    const adr = readRepoFile('docs/adr/0016-use-kanary-for-keyboard-remapping.md');
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');
    const kanaryModule = readRepoFile('nix/modules/kanary.nix');

    expect(fs.existsSync(path.join(repoPath, 'nix/home/karabiner.nix'))).toBe(false);
    expect(adr).toContain('Stop using Karabiner Elements');
    expect(adr).toContain('Stop installing Karabiner Elements');
    expect(adr).toContain('Stop generating `~/.config/karabiner/karabiner.json`');
    expect(adr).toContain('Require Kanary for local keyboard remapping');
    expect(adr).toContain('system.keyboard.remapCapsLockToControl');
    expect(darwinHost).toContain('../../modules/kanary.nix');
    expect(darwinHost).toContain('remapCapsLockToControl = true;');
    expect(kanaryModule).toContain('Kanary.app is required for keyboard remapping');
    expect(kanaryModule).toContain('https://kanary.download/download');
  });

  test('portable user dotfiles are managed without credential state', () => {
    const dotfilesModule = readRepoFile('nix/home/dotfiles.nix');

    [
      'dot/aerospace.toml',
      'dot/config/act/actrc',
      'dot/config/agent-deck/config.toml',
      'dot/config/codespaces-secrets/repos.txt',
      'dot/config/graphite/aliases',
      'git/gitignore',
      'dot/.peco/config.json',
      '.zsh/configs/aliases.zsh',
      '.zsh/configs/virtual/go.zsh',
      '.zsh/configs/virtual/php.zsh',
      '.zsh/configs/virtual/python.zsh',
      '.zsh/functions/git',
    ].forEach((relativePath) => {
      expect(fs.existsSync(path.join(repoPath, relativePath))).toBe(true);
    });

    expect(dotfilesModule).toContain('managedSource');
    expect(dotfilesModule).toContain('".aerospace.toml"');
    expect(dotfilesModule).toContain('".config/act/actrc"');
    expect(dotfilesModule).toContain('".config/agent-deck/config.toml"');
    expect(dotfilesModule).toContain('".config/codespaces-secrets/repos.txt"');
    expect(dotfilesModule).toContain('".config/graphite/aliases"');
    expect(dotfilesModule).toContain('".gitignore"');
    expect(dotfilesModule).toContain('".peco/config.json"');
    expect(dotfilesModule).toContain('".zsh/configs/virtual/go.zsh"');
    expect(dotfilesModule).toContain('".zsh/configs/virtual/php.zsh"');
    expect(dotfilesModule).toContain('".zsh/configs/virtual/python.zsh"');

    expect(dotfilesModule).not.toContain('user_config');
    expect(dotfilesModule).not.toContain('hosts.yml');
    expect(dotfilesModule).not.toContain('.npmrc');
    expect(dotfilesModule).not.toContain('.ssh');
    expect(dotfilesModule).not.toContain('.env.secret"');
  });

  test('agent local config collector is installed as a safe command', () => {
    const agentCommandsModule = readRepoFile('nix/home/agent-commands.nix');
    const packagesModule = readRepoFile('nix/home/packages.nix');
    const collectorScript = readRepoFile('script/agent/collect-local-configs.sh');
    const collectorPath = path.join(repoPath, 'script/agent/collect-local-configs.sh');

    expect(packagesModule).toContain('nodejs_24');
    expect(agentCommandsModule).toContain('".local/bin/agent-deck"');
    expect(agentCommandsModule).toContain('mkOutOfStoreSymlink "/opt/homebrew/bin/agent-deck"');
    expect(fs.statSync(collectorPath).mode & 0o111).toBeTruthy();
    expect(agentCommandsModule).toContain('".local/bin/agent-collect-local-configs"');
    expect(agentCommandsModule).toContain('configRoot + /script/agent/collect-local-configs.sh');
    expect(agentCommandsModule).toContain('executable = true;');
    expect(agentCommandsModule).toContain('force = true;');

    expect(collectorScript).toContain('config.local.json');
    expect(collectorScript).toContain('settings.local.json');
    expect(collectorScript).toContain('.env.local');
    expect(collectorScript).toContain('auth.json');
    expect(collectorScript).toContain('credentials*.json');
    expect(collectorScript).toContain('category\\tbytes\\tmtime\\tpath');
    expect(collectorScript).toContain('intentionally does not copy or print file contents');
  });
});
