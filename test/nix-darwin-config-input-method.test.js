const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('nix-darwin and home-manager input method configuration', () => {
  test('Google Japanese Input sources include hiragana and alphanumeric modes', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');

    expect(darwinHost).toContain('"com.apple.HIToolbox"');
    expect(darwinHost).toContain('AppleEnabledInputSources');
    expect(darwinHost).toContain('com.google.inputmethod.Japanese.base');
    expect(darwinHost).toContain('com.google.inputmethod.Japanese.Roman');
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
});
