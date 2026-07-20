'use strict';

/**
 * block_git_no_verify.py の挙動テスト。
 *
 * 文字列アサーションではなく実際にフックを起動する。`git commit -nm "msg"` のような
 * 結合フラグの扱いは、ソースを grep しても正しさを証明できないため。
 */

const path = require('path');
const { spawnSync } = require('child_process');

const hookPath = path.join(__dirname, '../.claude/hooks/block_git_no_verify.py');

/** フックに Bash ツールの入力を流し込み、終了コードと stderr を返す */
function runHook(command) {
  const payload = JSON.stringify({
    tool_name: 'Bash',
    tool_input: { command },
  });

  const result = spawnSync('python3', [hookPath], {
    input: payload,
    encoding: 'utf8',
    cwd: path.dirname(hookPath), // common.py を import できるようにする
  });

  return { status: result.status, stderr: result.stderr || '' };
}

/**
 * 提示された代替コマンドだけを取り出す。
 * stderr には説明文（--no-verify 等の語を含む）も出るため、全体で判定すると誤検知する。
 */
function suggestedCommand(stderr) {
  return stderr.trim().split('\n').pop().trim();
}

const BLOCKED_EXIT = 2;
const ALLOWED_EXIT = 0;

describe('block_git_no_verify.py', () => {
  describe('検証スキップフラグ', () => {
    test.each([
      ['git commit --no-verify -m "msg"', '--no-verify'],
      ['git commit -n -m "msg"', '-n'],
      ['git commit -nm "msg"', '-n を含む結合フラグ'],
      ['git commit -vn -m "msg"', '順序違いの結合フラグ'],
      ['git push --no-verify', 'push の --no-verify'],
      ['HUSKY=0 git commit -m "msg"', 'HUSKY=0'],
    ])('ブロックする: %s (%s)', (command) => {
      expect(runHook(command).status).toBe(BLOCKED_EXIT);
    });
  });

  describe('core.hooksPath による差し替え', () => {
    test.each([
      ['git -c core.hooksPath=/dev/null commit -m "msg"', '-c で差し替え'],
      ['git -c core.hooksPath= commit -m "msg"', '空値で差し替え'],
      ['git -ccore.hooksPath=/dev/null commit -m "msg"', '-c 値密着形式'],
      ['git -c CORE.HOOKSPATH=/dev/null commit -m "msg"', '大文字（gitのキーは大小無視）'],
      ['git config core.hooksPath /dev/null', '永続的な無効化'],
      ['git config --global core.hooksPath /dev/null', 'global への永続設定'],
      ['git --config-env=core.hooksPath=EVIL commit -m "msg"', '--config-env 経由'],
    ])('ブロックする: %s (%s)', (command) => {
      expect(runHook(command).status).toBe(BLOCKED_EXIT);
    });

    test('ブロックする: GIT_CONFIG_KEY 経由の差し替え', () => {
      const command =
        'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m "msg"';
      expect(runHook(command).status).toBe(BLOCKED_EXIT);
    });

    test.each([
      ['GIT_CONFIG_GLOBAL=/dev/null git commit -m "msg"', 'global設定の無効化'],
      ['GIT_CONFIG_SYSTEM=/dev/null git commit -m "msg"', 'system設定の無効化'],
    ])('ブロックする: %s (%s)', (command) => {
      expect(runHook(command).status).toBe(BLOCKED_EXIT);
    });
  });

  describe('正常なコマンドは通す（誤検知しない）', () => {
    test.each([
      'git commit -m "msg"',
      'git commit -am "msg"',
      'git commit',
      'git push',
      'git push -n', // push の -n は --dry-run であって検証スキップではない
      'git status',
      'git config user.name "keito"',
      'git config --get core.editor',
      'git -c color.ui=always log',
      'npm run test',
      'echo "--no-verify is not used here"', // git 以外の文脈
    ])('通す: %s', (command) => {
      expect(runHook(command).status).toBe(ALLOWED_EXIT);
    });

    test('入力が空でも落ちない', () => {
      expect(runHook('').status).toBe(ALLOWED_EXIT);
    });
  });

  describe('代替コマンドの提示', () => {
    test('--no-verify を除いた実行可能なコマンドを提示する', () => {
      const suggestion = suggestedCommand(runHook('git commit --no-verify -m "msg"').stderr);
      expect(suggestion).toBe('git commit -m msg');
    });

    test('結合フラグからは -n だけを取り除く', () => {
      const suggestion = suggestedCommand(runHook('git commit -nm "msg"').stderr);
      expect(suggestion).toBe('git commit -m msg');
    });

    test('core.hooksPath の指定ごと取り除く', () => {
      const suggestion = suggestedCommand(runHook('git -c core.hooksPath=/dev/null commit -m "msg"').stderr);
      expect(suggestion).toBe('git commit -m msg');
    });

    test('GIT_CONFIG_* の対の変数も残さない', () => {
      const suggestion = suggestedCommand(
        runHook('GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m "msg"')
          .stderr,
      );
      expect(suggestion).toBe('git commit -m msg');
    });
  });
});
