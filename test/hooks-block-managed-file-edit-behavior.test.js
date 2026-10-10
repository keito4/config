'use strict';

/**
 * block_managed_file_edit.py の挙動テスト。
 * 実際にフックを起動し、管理マーカー付きファイルのブロックと
 * それ以外の通過を確認する。
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const hookPath = path.join(__dirname, '../.claude/hooks/block_managed_file_edit.py');
const MARKER_LINE = '# Managed by keito4/config\n';

describe('block_managed_file_edit.py behavior', () => {
  let workDir;

  beforeEach(() => {
    workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'managed-edit-'));
  });

  afterEach(() => {
    fs.rmSync(workDir, { recursive: true, force: true });
  });

  /**
   * workDir を cwd としてフックを実行する。
   *
   * @param {object} payload - フックへの JSON ペイロード
   * @returns {{ status: number, stderr: string }}
   */
  function runHook(payload) {
    const result = spawnSync('python3', [hookPath], {
      input: JSON.stringify(payload),
      encoding: 'utf8',
      cwd: workDir,
      env: Object.assign({}, process.env, { PYTHONPATH: path.dirname(hookPath) }),
    });
    return { status: result.status ?? -1, stderr: result.stderr || '' };
  }

  /**
   * workDir 配下にファイルを作成する。
   *
   * @param {string} name - ファイル名
   * @param {string} content - 内容
   * @returns {string} 作成したファイルの絶対パス
   */
  function writeFile(name, content) {
    const file = path.join(workDir, name);
    fs.writeFileSync(file, content);
    return file;
  }

  it('blocks files carrying the managed marker in the head', () => {
    const file = writeFile('ci.yml', `${MARKER_LINE}name: CI\n`);
    const result = runHook({ tool_input: { file_path: file } });
    expect(result.status).toBe(2);
    expect(result.stderr).toContain('BLOCKED');
  });

  it('also reads the path key', () => {
    const file = writeFile('ci.yml', MARKER_LINE);
    expect(runHook({ tool_input: { path: file } }).status).toBe(2);
  });

  it('allows files without the marker', () => {
    const file = writeFile('plain.yml', 'name: CI\n');
    expect(runHook({ tool_input: { file_path: file } }).status).toBe(0);
  });

  it('ignores the marker beyond the first 5 lines', () => {
    const file = writeFile('late.yml', `a\nb\nc\nd\ne\n${MARKER_LINE}`);
    expect(runHook({ tool_input: { file_path: file } }).status).toBe(0);
  });

  it('allows missing files and empty payloads', () => {
    expect(runHook({ tool_input: { file_path: path.join(workDir, 'nope.yml') } }).status).toBe(0);
    expect(runHook({ tool_input: {} }).status).toBe(0);
    expect(runHook({}).status).toBe(0);
  });

  it('skips checks inside the config repo (sentinel present)', () => {
    fs.mkdirSync(path.join(workDir, '.github'));
    fs.writeFileSync(path.join(workDir, '.github/sync-downstream.json'), '{}');
    const file = writeFile('ci.yml', MARKER_LINE);
    expect(runHook({ tool_input: { file_path: file } }).status).toBe(0);
  });
});
