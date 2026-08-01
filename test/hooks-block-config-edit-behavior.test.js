'use strict';

/**
 * block_config_edit.py の挙動テスト。
 *
 * 内容検査（hooks-lifecycle.test.js）では「正しいパターンが定義されているか」を
 * 確認するにとどまる。このファイルでは実際にフックを起動し、
 * 保護対象ファイルがブロックされ、それ以外が通過することを確認する。
 */

const path = require('path');
const { spawnSync } = require('child_process');

const hookPath = path.join(__dirname, '../.claude/hooks/block_config_edit.py');

/**
 * フックに PreToolUse の入力を流し込み、終了コードと stderr を返す。
 *
 * @param {object} payload - フックへの JSON ペイロード
 * @returns {{ status: number, stderr: string }}
 */
function runHook(payload) {
  const result = spawnSync('python3', [hookPath], {
    input: JSON.stringify(payload),
    encoding: 'utf8',
    cwd: path.dirname(hookPath), // common.py を import できるようにする
  });
  return { status: result.status ?? -1, stderr: result.stderr || '' };
}

/**
 * file_path を持つ標準的な PreToolUse ペイロードを生成する。
 *
 * @param {string} filePath - 対象ファイルパス
 * @returns {object} PreToolUse ペイロード
 */
function makePayload(filePath) {
  return { tool_input: { file_path: filePath } };
}

const BLOCKED_EXIT = 2;
const ALLOWED_EXIT = 0;

describe('block_config_edit.py — behavioral tests', () => {
  describe('保護ファイルのブロック', () => {
    test.each([
      // ESLint
      ['eslint.config.mjs', '/workspace/eslint.config.mjs'],
      ['eslint.config.js', '/workspace/eslint.config.js'],
      ['eslint.config.cjs', '/workspace/eslint.config.cjs'],
      ['.eslintrc', '/repo/.eslintrc'],
      ['.eslintrc.json', '/project/.eslintrc.json'],
      ['.eslintrc.yml', '/project/.eslintrc.yml'],
      // Biome
      ['biome.json', '/project/biome.json'],
      ['biome.jsonc', '/project/biome.jsonc'],
      // Prettier
      ['.prettierrc', '/workspace/.prettierrc'],
      ['.prettierrc.json', '/workspace/.prettierrc.json'],
      ['prettier.config.js', '/workspace/prettier.config.js'],
      // TypeScript
      ['tsconfig.json', '/workspace/tsconfig.json'],
      // Ruff (Python)
      ['ruff.toml', '/project/ruff.toml'],
      // Lefthook
      ['lefthook.yml', '/workspace/lefthook.yml'],
      // ShellCheck
      ['.shellcheckrc', '/project/.shellcheckrc'],
      // Pre-commit
      ['.pre-commit-config.yaml', '/project/.pre-commit-config.yaml'],
      // Oxlint
      ['.oxlintrc.json', '/project/.oxlintrc.json'],
    ])('%s をブロックする', (filename, filePath) => {
      const { status } = runHook(makePayload(filePath));
      expect(status).toBe(BLOCKED_EXIT);
    });

    test('サブディレクトリ内の設定ファイルもブロックする（バセネームで判定）', () => {
      const { status } = runHook(makePayload('/deep/nested/path/tsconfig.json'));
      expect(status).toBe(BLOCKED_EXIT);
    });
  });

  describe('通常ファイルの通過', () => {
    test.each([
      ['package.json', '/workspace/package.json'],
      ['src/app.js', '/workspace/src/app.js'],
      ['README.md', '/workspace/README.md'],
      ['src/config.js', '/workspace/src/config.js'],
      ['.github/workflows/ci.yml', '/workspace/.github/workflows/ci.yml'],
      ['Dockerfile', '/workspace/Dockerfile'],
      ['docker-compose.yml', '/workspace/docker-compose.yml'],
    ])('%s を通過させる', (filename, filePath) => {
      const { status } = runHook(makePayload(filePath));
      expect(status).toBe(ALLOWED_EXIT);
    });
  });

  describe('エッジケース', () => {
    test('file_path が空文字のとき通過する', () => {
      const { status } = runHook(makePayload(''));
      expect(status).toBe(ALLOWED_EXIT);
    });

    test('tool_input が無いとき通過する', () => {
      const { status } = runHook({});
      expect(status).toBe(ALLOWED_EXIT);
    });

    test('path キーで指定された場合もブロックする', () => {
      const { status } = runHook({ tool_input: { path: '/workspace/tsconfig.json' } });
      expect(status).toBe(BLOCKED_EXIT);
    });
  });

  describe('エラーメッセージ', () => {
    test('ブロック時に BLOCKED を含む説明を stderr に出力する', () => {
      const { stderr } = runHook(makePayload('/workspace/eslint.config.mjs'));
      expect(stderr).toContain('BLOCKED');
    });

    test('ブロックしたファイル名を stderr に含める', () => {
      const { stderr } = runHook(makePayload('/workspace/biome.json'));
      expect(stderr).toContain('biome.json');
    });

    test('修正方針（FIX:）を stderr に含める', () => {
      const { stderr } = runHook(makePayload('/workspace/tsconfig.json'));
      expect(stderr).toContain('FIX');
    });
  });
});
