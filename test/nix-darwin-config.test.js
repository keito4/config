const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('nix-darwin and home-manager macOS configuration', () => {
  test('home-manager imports cmux and Karabiner modules', () => {
    const homeDefault = readRepoFile('nix/home/default.nix');

    expect(homeDefault).toContain('./cmux.nix');
    expect(homeDefault).toContain('./karabiner.nix');
  });

  test('Homebrew casks install cmux and input tooling', () => {
    const homebrewModule = readRepoFile('nix/modules/homebrew.nix');

    expect(homebrewModule).toContain('"cmux"');
    expect(homebrewModule).toContain('"karabiner-elements"');
    expect(homebrewModule).toContain('"google-japanese-ime"');
  });

  test('cmux terminal config leaves IME shortcuts unbound', () => {
    const cmuxModule = readRepoFile('nix/home/cmux.nix');

    expect(cmuxModule).toContain('home.file.".config/cmux/config"');
    expect(cmuxModule).toContain('force = true;');
    expect(cmuxModule).toContain('text = "";');
    expect(cmuxModule).not.toContain('C-j');
    expect(cmuxModule).not.toContain('C-Semicolon');
  });

  test('Karabiner maps Caps Lock and scopes cmux IME shortcuts', () => {
    const karabinerModule = readRepoFile('nix/home/karabiner.nix');

    expect(karabinerModule).toContain('home.file.".config/karabiner/karabiner.json"');
    expect(karabinerModule).toContain('keyboard_type_v2 = "jis"');
    expect(karabinerModule).toContain('key_code = "caps_lock"');
    expect(karabinerModule).toContain('key_code = "left_control"');
    expect(karabinerModule).toContain('^com\\\\.cmuxterm\\\\.app$');
    expect(karabinerModule).toContain('cmuxImeShortcut "j" "japanese_kana"');
    expect(karabinerModule).toContain('cmuxImeShortcut "semicolon" "japanese_eisuu"');
    expect(karabinerModule).toContain('cmuxImeShortcut "quote" "japanese_eisuu"');
  });
});
