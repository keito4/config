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

    expect(darwinHost).toContain('"com.apple.Spotlight"');
    expect(darwinHost).toContain('"NSStatusItem VisibleCC Item-0" = false;');
    expect(darwinHost).toContain('"com.jordanbaird.Ice"');
    expect(darwinHost).toContain('HideApplicationMenus = true;');
    expect(darwinHost).toContain('ShowOnClick = true;');
    expect(darwinHost).toContain('ShowOnScroll = true;');
    expect(darwinHost).toContain('UseIceBar = false;');
    expect(darwinHost).toContain('launchd.user.agents = {');
    expect(darwinHost).toContain('bettertouchtool = {');
    expect(darwinHost).toContain('ice = {');
    expect(darwinHost).toContain('raycast = {');
    expect(darwinHost).toContain('"/usr/bin/open"');
    expect(darwinHost).toContain('"-a"');
    expect(darwinHost).toContain('"BetterTouchTool"');
    expect(darwinHost).toContain('"Ice"');
    expect(darwinHost).toContain('"Raycast"');
    expect(darwinHost).toContain('RunAtLoad = true;');
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
    expect(homebrewModule).toContain('"duet"');
    expect(homebrewModule).toContain('"linear"');
    expect(homebrewModule).toContain('"readdle-spark"');
    expect(homebrewModule).toContain('"jordanbaird-ice"');
    expect(homebrewModule).toContain('"aerospace"');
    expect(homebrewModule).toContain('"bettertouchtool"');
    expect(homebrewModule).toContain('"raycast"');
    expect(homebrewModule).not.toContain('"mattermost"');
    expect(homebrewModule).not.toContain('"messenger"');
    expect(homebrewModule).not.toContain('"alfred"');
    expect(homebrewModule).not.toContain('"karabiner-elements"');
    expect(homebrewModule).not.toContain('"bartender"');
    expect(homebrewModule).not.toContain('"rancher"');
    expect(homebrewModule).not.toContain('"google-cloud-sdk"');
    expect(homebrewModule).not.toContain('"tailscale"');
    expect(homebrewModule).not.toContain('"koekeishiya/formulae/yabai"');
  });

  test('AeroSpace owns window management with app workspace routing', () => {
    const aerospaceConfig = readRepoFile('dot/aerospace.toml');

    expect(aerospaceConfig).toContain('config-version = 2');
    expect(aerospaceConfig).toContain('start-at-login = true');
    expect(aerospaceConfig).toContain('auto-reload-config = true');
    expect(aerospaceConfig).toContain('persistent-workspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]');
    expect(aerospaceConfig).toContain('inner.horizontal = 6');
    expect(aerospaceConfig).toContain('outer.top =        6');
    expect(aerospaceConfig).toContain('[[on-window-detected]]');
    expect(aerospaceConfig).toContain("if.app-id = 'com.cmuxterm.app'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.google.Chrome'");
    expect(aerospaceConfig).toContain("if.app-id = 'company.thebrowser.Browser'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.todesktop.230313mzl4w4u92'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.openai.codex'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.anthropic.claudefordesktop'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.tinyspeck.slackmacgap'");
    expect(aerospaceConfig).toContain("if.app-id = 'notion.id'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.readdle.SparkDesktop'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.raycast.macos'");
    expect(aerospaceConfig).toContain("if.app-id = 'com.hegenberg.BetterTouchTool'");
    expect(aerospaceConfig).toContain("run = 'move-node-to-workspace 9'");
  });

  test('BetterTouchTool gesture setup is GitHub-managed and preserves existing triggers', () => {
    const bttSetup = readRepoFile('script/macos/setup-bettertouchtool.js');
    const adr = readRepoFile('docs/adr/0017-manage-bettertouchtool-gestures.md');

    expect(fs.existsSync(path.join(repoPath, 'script/macos/setup-bettertouchtool.js'))).toBe(true);
    expect(bttSetup).toContain("Application('/Applications/BetterTouchTool.app')");
    expect(bttSetup).toContain('existingUuids.has(trigger.BTTUUID)');
    expect(bttSetup).not.toContain('delete_triggers');
    expect(bttSetup).toContain('CODEX-BTT-CMD-W');
    expect(bttSetup).toContain("BTTShortcutToSend: '55,13'");
    expect(bttSetup).toContain("const aerospace = '/opt/homebrew/bin/aerospace'");
    expect(bttSetup).toContain('workspace --wrap-around next');
    expect(bttSetup).toContain('workspace --wrap-around prev');
    expect(bttSetup).toContain('workspace-back-and-forth');
    expect(bttSetup).toContain('focus left');
    expect(bttSetup).toContain('/usr/bin/open -a Raycast');
    expect(adr).toContain('The script adds only missing `CODEX-BTT-*` triggers.');
    expect(adr).toContain('The script does not delete existing triggers');
    expect(adr).toContain('3 finger swipe down: send `Cmd+W`.');
  });

  test('skhd binds IME shortcuts without Karabiner', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    // TCC 許可を安定させるため、nix store 直参照ではなく
    // /usr/local/bin/skhd (activation でコピーした安定パス) から起動する
    expect(darwinHost).toContain('environment.etc."skhdrc".text');
    expect(darwinHost).toContain('install -m 755 "${pkgs.skhd}/bin/skhd" /usr/local/bin/skhd');
    expect(darwinHost).toContain('launchd.user.agents.skhd');
    expect(darwinHost).toContain('"/usr/local/bin/skhd"');
    expect(darwinHost).toContain('ctrl + shift - j');
    expect(darwinHost).toContain('ctrl + shift - 0x29');
    expect(darwinHost).toContain('/Users/${username}/.local/bin/send-ime-key kana');
    expect(darwinHost).toContain('/Users/${username}/.local/bin/send-ime-key eisuu');
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

  test('send-ime-key emits physical kana/eisuu keys for reliable IME switching', () => {
    const inputSourceModule = readRepoFile('nix/home/input-source.nix');
    const sendKeyWrapper = readRepoFile('script/macos/send-ime-key.sh');
    const sendKeySwift = readRepoFile('script/macos/send-ime-key.swift');

    expect(inputSourceModule).toContain('".local/share/input-source/send-ime-key.swift"');
    expect(inputSourceModule).toContain('".local/bin/send-ime-key"');
    expect(sendKeyWrapper).toContain('/input-source/send-ime-key.swift');
    expect(sendKeySwift).toContain('return 104'); // かな
    expect(sendKeySwift).toContain('return 102'); // 英数
    expect(sendKeySwift).toContain('.cghidEventTap');
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

  test('Kanary Caps Lock to Control is enforced from home-manager', () => {
    const homeDefault = readRepoFile('nix/home/default.nix');
    const kanaryHome = readRepoFile('nix/home/kanary.nix');
    const enforceScript = readRepoFile('script/macos/kanary-enforce-caps-control.sh');
    const adr = readRepoFile('docs/adr/0016-use-kanary-for-keyboard-remapping.md');

    expect(homeDefault).toContain('./kanary.nix');
    expect(kanaryHome).toContain('.local/bin/kanary-enforce-caps-control');
    expect(kanaryHome).toContain('home.activation.enforceKanaryCapsControl');
    expect(enforceScript).toContain('download.kanary.settings');
    expect(enforceScript).toContain('capsLockRemappedToControl');
    expect(adr).toContain('kanary-enforce-caps-control');
  });

  test('portable user dotfiles are managed without credential state', () => {
    const dotfilesModule = readRepoFile('nix/home/dotfiles.nix');

    [
      'dot/aerospace.toml',
      'dot/config/act/actrc',
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
    // 組織情報を含む設定は keito4/private-config から out-of-store symlink で参照する
    expect(dotfilesModule).toContain('privateConfig');
    expect(dotfilesModule).toContain('mkOutOfStoreSymlink');
    expect(dotfilesModule).toContain('".config/agent-deck/config.toml"');
    expect(dotfilesModule).toContain('".config/codespaces-secrets/repos.txt"');
    expect(dotfilesModule).toContain('".config/graphite/aliases"');

    // 組織情報を含む設定は private-config（非公開リポジトリ）の out-of-store symlink で管理する
    expect(dotfilesModule).toContain('mkOutOfStoreSymlink');
    expect(dotfilesModule).toContain('keito4/private-config');
    expect(dotfilesModule).toContain('".config/agent-deck/config.toml" = privateConfig');
    expect(dotfilesModule).toContain('".config/codespaces-secrets/repos.txt" = privateConfig');
    expect(dotfilesModule).toContain('".config/devcontainer-env-keys.txt" = privateConfig');
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

  test('devcontainer env loader reads approved credential keys from private allowlist', () => {
    const zshModule = readRepoFile('nix/home/zsh.nix');
    const devcontainerEnvLoader = readRepoFile('.zsh/configs/pre/devcontainer-env.zsh');

    [zshModule, devcontainerEnvLoader].forEach((loader) => {
      // 許可キーはインライン列挙せず private-config 管理の外部ファイルから読む
      expect(loader).toContain('devcontainer-env-keys.txt');
      expect(loader).toContain('.devcontainer.env');

      // 組織名を含むキーや 1Password サービストークンを公開リポジトリに残さない
      ['ELU_SENTRY_TOKEN', 'ELU_NOTION_API_KEY', 'OYKOT_NOTION_API_KEY', 'OP_SERVICE_ACCOUNT_TOKEN'].forEach(
        (envKey) => {
          expect(loader).not.toContain(envKey);
        },
      );
    });
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

  test('claude-lmstudio launcher is installed as an executable command', () => {
    const agentCommandsModule = readRepoFile('nix/home/agent-commands.nix');
    const launcherScript = readRepoFile('script/agent/claude-lmstudio.sh');
    const launcherPath = path.join(repoPath, 'script/agent/claude-lmstudio.sh');

    expect(agentCommandsModule).toContain('".local/bin/claude-lmstudio"');
    expect(agentCommandsModule).toContain('configRoot + /script/agent/claude-lmstudio.sh');
    expect(fs.statSync(launcherPath).mode & 0o111).toBeTruthy();

    // Points Claude Code at the local LM Studio Anthropic-compatible endpoint.
    expect(launcherScript).toContain('ANTHROPIC_BASE_URL');
    expect(launcherScript).toContain('http://localhost:1234');
    expect(launcherScript).toContain('exec claude --model');
    // Default to an MLX build; GGUF fails Claude Code tool use on the llama.cpp grammar parser.
    expect(launcherScript).toContain('qwen/qwen3-coder-next');
    expect(launcherScript).toContain('MLX');

    // LM Studio's JIT loader defaults to an 8k context, too small for Claude Code's
    // system prompt, so the launcher must load the model with a usable window itself.
    expect(launcherScript).toContain('LMSTUDIO_CONTEXT_LENGTH');
    expect(launcherScript).toContain('--context-length');

    // Loading alongside a stale small-context copy is not enough: LM Studio routes by
    // model key and serves the stale copy, so the small copies must be unloaded first.
    expect(launcherScript).toContain('lms unload');
  });
});
