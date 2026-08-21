const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('AeroSpace window management and BetterTouchTool gestures', () => {
  test('AeroSpace owns window management and tiles windows where they open', () => {
    const aerospaceConfig = readRepoFile('dot/aerospace.toml');

    expect(aerospaceConfig).toContain('config-version = 2');
    expect(aerospaceConfig).toContain('start-at-login = true');
    expect(aerospaceConfig).toContain('auto-reload-config = true');
    expect(aerospaceConfig).toContain('persistent-workspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]');
    expect(aerospaceConfig).toContain('inner.horizontal = 6');
    expect(aerospaceConfig).toContain('outer.top =        6');
    expect(aerospaceConfig).toContain("default-root-container-layout = 'tiles'");

    // アプリ毎の専用ワークスペース割当は撤廃済み。各アプリを別ワークスペースへ
    // 固定するとアプリ間フォーカス移動のたびに表示ワークスペースが切り替わり、
    // 直前のアプリが画面から消えてしまうため。撤廃後はウィンドウが開いた場所に
    // タイルされ、同一ワークスペース上で自由にパネル分割できる。
    expect(aerospaceConfig).not.toContain('[[on-window-detected]]');
    expect(aerospaceConfig).not.toContain('if.app-id');
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
});
