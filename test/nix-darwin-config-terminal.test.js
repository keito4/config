const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('home-manager cmux terminal configuration', () => {
  test('home-manager imports cmux and input source helpers without Karabiner', () => {
    const homeDefault = readRepoFile('nix/home/default.nix');

    expect(homeDefault).toContain('./dotfiles.nix');
    expect(homeDefault).toContain('./agent-commands.nix');
    expect(homeDefault).toContain('./input-source.nix');
    expect(homeDefault).toContain('./cmux.nix');
    expect(homeDefault).not.toContain('./tmux.nix');
    expect(homeDefault).not.toContain('./karabiner.nix');
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

  test('zsh drops a TERMINFO that cannot resolve the current TERM', () => {
    // cmux.app が TERMINFO に自前の terminfo ディレクトリを差し込むため、tmux 内
    // (TERM=tmux-256color) では termbox-go 系 CLI (peco) が Init に失敗して panic する。
    const zshModule = readRepoFile('nix/home/zsh.nix');

    expect(zshModule).toContain('envExtra');
    expect(zshModule).toContain('_terminfo_entries');
    expect(zshModule).toContain('unset TERMINFO');
  });

  test('agent-deck attach drops an unusable TERMINFO before invoking peco', () => {
    // .zshenv のガードより前に起動した古いシェルから呼ばれても peco が panic しないよう、
    // ada 側でも同じ判定を行う。
    const attachScript = readRepoFile('script/agent/agent-deck-attach.sh');

    expect(attachScript).toContain('compgen -G "$TERMINFO/*/$TERM"');
    expect(attachScript).toContain('unset TERMINFO');
  });

  test('agent-deck attach reports failures instead of exiting silently', () => {
    // set -euo pipefail と 2>/dev/null の組み合わせで、どの段階で失敗しても
    // 何も表示されずに終了していた。失敗は必ず理由を出す。
    const attachScript = readRepoFile('script/agent/agent-deck-attach.sh');

    expect(attachScript).toContain('die()');
    expect(attachScript).toContain('agent-deck list --json に失敗しました');
    expect(attachScript).toContain('アタッチできるセッションがありません');
    expect(attachScript).toContain('peco が異常終了しました');
    expect(attachScript).toContain('switch-client に失敗しました');
    expect(attachScript).not.toContain('agent-deck list --json 2>/dev/null');
  });

  test('agent-deck attach tells you when the pick is the session you are in', () => {
    // cmux は 1 タブ = 1 セッションで tmux クライアントを貼り付けるため、いま自分が
    // いるセッションを選ぶと switch-client が no-op になり「何も起きない」ように見える。
    const attachScript = readRepoFile('script/agent/agent-deck-attach.sh');

    expect(attachScript).toContain("tmux display-message -p '#{session_name}'");
    expect(attachScript).toContain('すでにこのセッションにいます');
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
});
