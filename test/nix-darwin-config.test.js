const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('nix-darwin and home-manager macOS configuration', () => {
  test('home-manager imports cmux and Karabiner modules', () => {
    const homeDefault = readRepoFile('nix/home/default.nix');

    expect(homeDefault).toContain('./dotfiles.nix');
    expect(homeDefault).toContain('./agent-commands.nix');
    expect(homeDefault).toContain('./cmux.nix');
    expect(homeDefault).toContain('./karabiner.nix');
  });

  test('Homebrew casks install cmux and input tooling', () => {
    const homebrewModule = readRepoFile('nix/modules/homebrew.nix');

    expect(homebrewModule).toContain('"android-studio"');
    expect(homebrewModule).toContain('"cmux"');
    expect(homebrewModule).toContain('"flutter"');
    expect(homebrewModule).toContain('"karabiner-elements"');
    expect(homebrewModule).toContain('"mattermost"');
    expect(homebrewModule).toContain('"google-japanese-ime"');
    expect(homebrewModule).not.toContain('"bartender"');
    expect(homebrewModule).not.toContain('"rancher"');
    expect(homebrewModule).not.toContain('"google-cloud-sdk"');
    expect(homebrewModule).not.toContain('"tailscale"');
  });

  test('cmux terminal config leaves IME shortcuts unbound', () => {
    const cmuxModule = readRepoFile('nix/home/cmux.nix');

    expect(cmuxModule).toContain('home.file.".config/cmux/config"');
    expect(cmuxModule).toContain('force = true;');
    expect(cmuxModule).toContain('text = "";');
    expect(cmuxModule).not.toContain('C-j');
    expect(cmuxModule).not.toContain('C-Semicolon');
  });

  test('cmux app config manages agent-friendly defaults', () => {
    const cmuxModule = readRepoFile('nix/home/cmux.nix');

    expect(cmuxModule).toContain('home.file.".config/cmux/cmux.json"');
    expect(cmuxModule).toContain('"$schema" = cmuxSchema;');
    expect(cmuxModule).toContain('confirmQuit = "dirty-only";');
    expect(cmuxModule).toContain('workspaceInheritWorkingDirectory = true;');
    expect(cmuxModule).toContain('socketControlMode = "cmuxOnly";');
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

  test('Karabiner maps Caps Lock and scopes cmux IME shortcuts', () => {
    const karabinerModule = readRepoFile('nix/home/karabiner.nix');

    expect(karabinerModule).toContain('home.file.".config/karabiner/karabiner.json"');
    expect(karabinerModule).not.toContain('keyboard_type_v2 = "jis"');
    expect(karabinerModule).toContain('key_code = "caps_lock"');
    expect(karabinerModule).toContain('key_code = "left_control"');
    expect(karabinerModule).toContain('^com\\\\.cmuxterm\\\\.app$');
    expect(karabinerModule).toContain('cmuxJapaneseInputSource = "com.google.inputmethod.Japanese.base";');
    expect(karabinerModule).toContain('cmuxEnglishInputSource = "com.google.inputmethod.Japanese.Roman";');
    expect(karabinerModule).toContain('shell_command = "${inputSourceCommand} ${inputSourceID}"');
    expect(karabinerModule).toContain('cmuxImeShortcut "j" cmuxJapaneseInputSource');
    expect(karabinerModule).toContain('cmuxImeShortcut "semicolon" cmuxEnglishInputSource');
    expect(karabinerModule).toContain('cmuxImeShortcut "quote" cmuxEnglishInputSource');
    expect(karabinerModule).toContain('cmuxCapsLockImeShortcut "j" cmuxJapaneseInputSource');
    expect(karabinerModule).toContain('cmuxImeSimultaneousShortcut "left_control" "j" cmuxJapaneseInputSource');
    expect(karabinerModule).toContain('home.file.".local/bin/agent-select-input-source"');
    expect(karabinerModule).toContain('source = ../../script/macos/agent-select-input-source.sh;');

    const selectInputSourceScript = readRepoFile('script/macos/select-input-source.swift');
    expect(selectInputSourceScript).toContain('TISSelectInputSource');
    expect(selectInputSourceScript).toContain('TISCopyCurrentKeyboardInputSource');

    const selectInputSourceWrapper = readRepoFile('script/macos/agent-select-input-source.sh');
    expect(selectInputSourceWrapper).toContain('exec /usr/bin/xcrun swift "$src" "$@"');
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
    const collectorScript = readRepoFile('script/agent/collect-local-configs.sh');
    const collectorPath = path.join(repoPath, 'script/agent/collect-local-configs.sh');

    expect(fs.statSync(collectorPath).mode & 0o111).toBeTruthy();
    expect(agentCommandsModule).toContain('".local/bin/agent-collect-local-configs"');
    expect(agentCommandsModule).toContain('../../script/agent/collect-local-configs.sh');
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
