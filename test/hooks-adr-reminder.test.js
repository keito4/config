'use strict';

/**
 * post_commit_adr_reminder.py の挙動テスト。
 *
 * hooks-lifecycle.test.js はソースの文字列一致検査にとどまる。
 * このファイルでは実際にフックを起動し、「スキップすべき場面では
 * 出力を一切出さない」という安全動作（フェイルオープン設計）を確認する。
 *
 * ADR リマインダーを実際に出力するケース（アーキテクチャ的変更を含む
 * コミット直後）は git の状態に依存するため統合テストとなり、
 * このファイルでは範囲外とする。
 */

const path = require('path');
const { spawnSync } = require('child_process');

const hookPath = path.join(__dirname, '../.claude/hooks/post_commit_adr_reminder.py');

/**
 * フックに PostToolUse 入力を流し込み、終了コードと stdout を返す。
 *
 * @param {object} payload - PostToolUse の JSON ペイロード
 * @returns {{ status: number, stdout: string }}
 */
function runHook(payload) {
  const result = spawnSync('python3', [hookPath], {
    input: JSON.stringify(payload),
    encoding: 'utf8',
    cwd: path.dirname(hookPath), // common.py を import できるようにする
  });
  return { status: result.status ?? -1, stdout: result.stdout || '' };
}

/** 成功した git commit コマンドに対する標準的な PostToolUse ペイロード */
function makeCommitPayload({
  command = 'git commit -m "chore: update deps"',
  exitCode = 0,
  stdout = '[main abc1234] chore: update deps',
  stderr = '',
} = {}) {
  return {
    tool_name: 'Bash',
    tool_input: { command },
    tool_response: { exit_code: exitCode, stdout, stderr },
  };
}

describe('post_commit_adr_reminder.py — スキップ条件', () => {
  describe('Bash ツール以外はスキップ', () => {
    test.each([
      ['Edit', { tool_name: 'Edit', tool_input: { file_path: 'package.json' }, tool_response: {} }],
      ['Read', { tool_name: 'Read', tool_input: { file_path: 'package.json' }, tool_response: {} }],
      ['Write', { tool_name: 'Write', tool_input: { file_path: 'package.json' }, tool_response: {} }],
    ])('%s ツールでは何も出力しない', (_label, payload) => {
      const { status, stdout } = runHook(payload);
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });
  });

  describe('git commit 以外のコマンドはスキップ', () => {
    test.each([
      ['git status', makeCommitPayload({ command: 'git status' })],
      ['git push', makeCommitPayload({ command: 'git push origin main' })],
      ['git add .', makeCommitPayload({ command: 'git add .' })],
      ['npm install', makeCommitPayload({ command: 'npm install' })],
      ['echo hello', makeCommitPayload({ command: 'echo hello' })],
    ])('`%s` では何も出力しない', (_label, payload) => {
      const { status, stdout } = runHook(payload);
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });
  });

  describe('ドライラン・ヘルプフラグはスキップ', () => {
    test('--help フラグ付きコミットではスキップ', () => {
      const { status, stdout } = runHook(makeCommitPayload({ command: 'git commit --help' }));
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });

    test('-h フラグ付きコミットではスキップ', () => {
      const { status, stdout } = runHook(makeCommitPayload({ command: 'git commit -h' }));
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });

    test('--dry-run フラグ付きコミットではスキップ', () => {
      const { status, stdout } = runHook(makeCommitPayload({ command: 'git commit --dry-run -m "test"' }));
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });
  });

  describe('コミット失敗時はスキップ', () => {
    test('exit_code が 1 のときはスキップ', () => {
      const { status, stdout } = runHook(makeCommitPayload({ exitCode: 1 }));
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });

    test('exit_code が 128 のときはスキップ', () => {
      const { status, stdout } = runHook(makeCommitPayload({ exitCode: 128 }));
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });

    test('exit_code が null かつ stdout がコミット成功パターンに一致しないときはスキップ', () => {
      const payload = {
        tool_name: 'Bash',
        tool_input: { command: 'git commit -m "test"' },
        tool_response: {
          exit_code: null,
          stdout: 'nothing to commit, working tree clean',
          stderr: '',
        },
      };
      const { status, stdout } = runHook(payload);
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });

    test('exit_code が null かつ stdout が空のときはスキップ', () => {
      const payload = {
        tool_name: 'Bash',
        tool_input: { command: 'git commit -m "test"' },
        tool_response: { exit_code: null, stdout: '', stderr: '' },
      };
      const { status, stdout } = runHook(payload);
      expect(status).toBe(0);
      expect(stdout.trim()).toBe('');
    });
  });
});
