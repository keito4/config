const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('AeroSpace window management and BetterTouchTool gestures', () => {
  test('AeroSpace owns window management with app workspace routing', () => {
    const aerospaceConfig = readRepoFile('dot/aerospace.toml');

    expect(aerospaceConfig).toContain('config-version = 2');
    // 自動起動は無効化。アプリ毎のワークスペース分離により、アプリ切替時に表示
    // ワークスペースが切り替わり直前のアプリが画面から消えるため。本体は残す。
    expect(aerospaceConfig).toContain('start-at-login = false');
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
});
