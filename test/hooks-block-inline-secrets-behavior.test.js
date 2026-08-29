'use strict';

/**
 * block_inline_secrets.py の挙動テスト。
 *
 * hooks-command-safety.test.js は「SECRET_PATTERNS に想定パターンの正規表現文字列が
 * 含まれているか」という静的な内容検査に留まる。このファイルでは実際にフックを
 * 起動し、埋め込まれた資格情報を含むコマンドが本当にブロックされ、変数参照や
 * 公開デモ用トークンを含む安全なコマンドが通過することを確認する。
 */

const path = require('path');
const { spawnSync } = require('child_process');

const hookPath = path.join(__dirname, '../.claude/hooks/block_inline_secrets.py');

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

const BLOCKED_EXIT = 2;
const ALLOWED_EXIT = 0;

describe('block_inline_secrets.py — behavioral tests', () => {
  describe('インラインの資格情報をブロックする', () => {
    test.each([
      ['AWS access key id', 'export AWS_ACCESS_KEY_ID=AKIAABCDEFGHIJKLMNOP'],
      ['AWS secret access key', 'export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY1"'],
      ['GitHub personal access token', 'curl -H "Authorization: token ghp_' + 'a'.repeat(36) + '"'],
      ['Anthropic API key', 'export ANTHROPIC_API_KEY=sk-ant-' + 'a'.repeat(95)],
      ['Slack token', 'export SLACK_TOKEN=xoxb-1234567890-abcdefghij'],
      ['Google API key', 'export GOOGLE_API_KEY=AIza' + 'a'.repeat(35)],
      ['private key block', 'echo "-----BEGIN RSA PRIVATE KEY-----"'],
    ])('%s を検知してブロックする', (_label, command) => {
      const { status, stderr } = runHook(command);
      expect(status).toBe(BLOCKED_EXIT);
      expect(stderr).toContain('認証情報が埋め込まれています');
    });
  });

  describe('安全なコマンドは通過させる', () => {
    test.each([
      ['変数参照のみ', 'export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"'],
      ['シークレットを含まない一般的なコマンド', 'npm run build'],
      [
        '公開 Supabase デモ JWT はホワイトリスト対象',
        'export SUPABASE_ANON_KEY=eyJpc3MiOiJzdXBhYmFzZS1kZW1v.eyJyb2xlIjoiYW5vbiJ9',
      ],
    ])('%s', (_label, command) => {
      const { status } = runHook(command);
      expect(status).toBe(ALLOWED_EXIT);
    });

    test('空コマンドではブロックしない', () => {
      const { status } = runHook('');
      expect(status).toBe(ALLOWED_EXIT);
    });
  });
});
