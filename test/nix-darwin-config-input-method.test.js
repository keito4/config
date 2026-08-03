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

  test('skhd copy is signed with a stable identity so the accessibility grant survives updates', () => {
    const darwinHost = readRepoFile('nix/hosts/darwin/default.nix');
    const setupScript = readRepoFile('script/macos/setup-skhd-signing.sh');

    // nixpkgs の skhd は ad-hoc 署名なので TCC が cdhash で許可を紐付ける。
    // 更新でコピーの中身が変わると許可が失効し、しかも ad-hoc バイナリは
    // launchd 起動時に許可が適用されない。固定 identity で署名して回避する。
    expect(darwinHost).toContain('skhdSigningIdentity=skhd-local-signing');
    expect(darwinHost).toContain('/usr/bin/codesign --force --sign "$skhdSigningIdentity"');
    expect(darwinHost).toContain('--identifier org.nixos.skhd');

    // identity が未作成でも activation を壊さないこと (署名を飛ばすだけ)
    expect(darwinHost).toContain('/usr/bin/security find-identity -v -p codesigning');
    expect(darwinHost).toContain('run script/macos/setup-skhd-signing.sh');

    // 署名するとコピーは元バイナリと一致しなくなるため、cmp ではなく
    // 元バイナリのハッシュを控えて入れ替え要否を判定する
    expect(darwinHost).toContain('skhdStampFile=/usr/local/bin/.skhd.nix-source-hash');
    expect(darwinHost).not.toContain('cmp -s "${pkgs.skhd}/bin/skhd" /usr/local/bin/skhd');

    // セットアップ側は System キーチェーンに入れる (root の activation から使うため)
    expect(setupScript).toContain('IDENTITY="skhd-local-signing"');
    expect(setupScript).toContain('KEYCHAIN="/Library/Keychains/System.keychain"');
    expect(setupScript).toContain('extendedKeyUsage       = critical,codeSigning');
    expect(setupScript).toContain('add-trusted-cert');
  });

  test('PKCS12 is generated so that macOS security import can verify its MAC', () => {
    const setupScript = readRepoFile('script/macos/setup-skhd-signing.sh');

    // macOS の Security framework は OpenSSL 3.x 既定の AES-256-CBC + SHA-256 MAC を
    // 検証できず "MAC verification failed" になる。Homebrew の openssl が PATH で
    // 優先されうるため、既定が macOS 互換な system の LibreSSL を明示的に使う。
    expect(setupScript).toContain('OPENSSL=/usr/bin/openssl');
    expect(setupScript).not.toMatch(/^\s*openssl (req|pkcs12|rand)\b/m);

    // `security import` は空パスワードの PKCS12 を受け付けず常に MAC verification
    // failed になるため、使い捨てのランダムパスワードを付ける。
    expect(setupScript).toContain('P12_PASSWORD="$("$OPENSSL" rand -hex 16)"');
    expect(setupScript).toContain('-passout "pass:$P12_PASSWORD"');
    expect(setupScript).toContain('-P "$P12_PASSWORD"');
    expect(setupScript).not.toContain('-passout pass: ');
    expect(setupScript).not.toContain('-P "" ');
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
