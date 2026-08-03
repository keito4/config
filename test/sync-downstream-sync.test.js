'use strict';

/**
 * Tests for the file sync operations in script/sync-downstream.js.
 *
 * Covers syncFiles (copy / unchanged / ignored / check mode) and
 * sanitizeForDownstream (.claude/settings.json stripping) using temporary
 * directories under .context/.
 *
 * Manifest schema validation and per-repo file resolution are tested in
 * sync-downstream.test.js.
 */

const fs = require('fs');
const path = require('path');

const { sanitizeForDownstream, syncFiles } = require('../script/sync-downstream');

const repoRoot = path.resolve(__dirname, '..');

function makeTempDir(prefix) {
  const contextDir = path.join(repoRoot, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  return fs.mkdtempSync(path.join(contextDir, `${prefix}-`));
}

function writeFile(root, relativePath, content) {
  const absolute = path.join(root, relativePath);
  fs.mkdirSync(path.dirname(absolute), { recursive: true });
  fs.writeFileSync(absolute, content);
}

describe('syncFiles', () => {
  let configRoot;
  let targetRoot;

  beforeEach(() => {
    configRoot = makeTempDir('sync-src');
    targetRoot = makeTempDir('sync-dst');
  });

  afterEach(() => {
    fs.rmSync(configRoot, { recursive: true, force: true });
    fs.rmSync(targetRoot, { recursive: true, force: true });
  });

  function resolvedFor(entries, exclude = []) {
    return { entries, exclude: new Set(exclude) };
  }

  test('copies a new file and reports it', () => {
    writeFile(configRoot, 'templates/a.yml', 'name: a\n');
    const resolved = resolvedFor([{ source: 'templates/a.yml', target: '.github/workflows/a.yml' }]);

    const result = syncFiles(configRoot, targetRoot, resolved);

    expect(result.copied).toEqual(['.github/workflows/a.yml']);
    expect(fs.readFileSync(path.join(targetRoot, '.github/workflows/a.yml'), 'utf8')).toBe('name: a\n');
  });

  test('reports identical files as unchanged without rewriting', () => {
    writeFile(configRoot, 'templates/a.yml', 'name: a\n');
    writeFile(targetRoot, '.github/workflows/a.yml', 'name: a\n');
    const resolved = resolvedFor([{ source: 'templates/a.yml', target: '.github/workflows/a.yml' }]);

    const result = syncFiles(configRoot, targetRoot, resolved);

    expect(result.copied).toEqual([]);
    expect(result.unchanged).toEqual(['.github/workflows/a.yml']);
  });

  test('sanitizes .claude/settings.json before writing it downstream', () => {
    writeFile(
      configRoot,
      '.claude/settings.json',
      JSON.stringify({
        enabledPlugins: { 'commit-commands@claude-plugins-official': true },
        hooks: { SessionStart: [{ hooks: [{ type: 'command', command: 'agent-deck hook-handler' }] }] },
        permissions: { allow: ['WebSearch'] },
      }),
    );
    const resolved = resolvedFor([{ source: '.claude/settings.json', target: '.claude/settings.json' }]);

    syncFiles(configRoot, targetRoot, resolved);

    const written = JSON.parse(fs.readFileSync(path.join(targetRoot, '.claude/settings.json'), 'utf8'));
    expect(written).toEqual({ hooks: {}, permissions: { allow: ['WebSearch'] } });
  });

  test('overwrites a locally modified file', () => {
    writeFile(configRoot, 'templates/a.yml', 'name: upstream\n');
    writeFile(targetRoot, '.github/workflows/a.yml', 'name: local-change\n');
    const resolved = resolvedFor([{ source: 'templates/a.yml', target: '.github/workflows/a.yml' }]);

    const result = syncFiles(configRoot, targetRoot, resolved);

    expect(result.copied).toEqual(['.github/workflows/a.yml']);
    expect(fs.readFileSync(path.join(targetRoot, '.github/workflows/a.yml'), 'utf8')).toBe('name: upstream\n');
  });

  test('walks directory entries recursively and skips pycache artifacts', () => {
    writeFile(configRoot, '.claude/hooks/common.py', 'x = 1\n');
    writeFile(configRoot, '.claude/hooks/sub/util.py', 'y = 2\n');
    writeFile(configRoot, '.claude/hooks/__pycache__/common.cpython-312.pyc', 'binary');
    const resolved = resolvedFor([{ source: '.claude/hooks/', target: '.claude/hooks/' }]);

    const result = syncFiles(configRoot, targetRoot, resolved);

    expect(result.copied.sort()).toEqual(['.claude/hooks/common.py', '.claude/hooks/sub/util.py']);
    expect(fs.existsSync(path.join(targetRoot, '.claude/hooks/__pycache__'))).toBe(false);
  });

  test('respects the per-repo exclude list', () => {
    writeFile(configRoot, '.claude/hooks/common.py', 'x = 1\n');
    writeFile(configRoot, '.claude/hooks/other.py', 'z = 3\n');
    const resolved = resolvedFor([{ source: '.claude/hooks/', target: '.claude/hooks/' }], ['.claude/hooks/common.py']);

    const result = syncFiles(configRoot, targetRoot, resolved);

    expect(result.copied).toEqual(['.claude/hooks/other.py']);
    expect(result.excluded).toEqual(['.claude/hooks/common.py']);
    expect(fs.existsSync(path.join(targetRoot, '.claude/hooks/common.py'))).toBe(false);
  });

  test('check mode reports differences without writing', () => {
    writeFile(configRoot, 'templates/a.yml', 'name: a\n');
    const resolved = resolvedFor([{ source: 'templates/a.yml', target: '.github/workflows/a.yml' }]);

    const result = syncFiles(configRoot, targetRoot, resolved, { check: true });

    expect(result.copied).toEqual(['.github/workflows/a.yml']);
    expect(fs.existsSync(path.join(targetRoot, '.github/workflows/a.yml'))).toBe(false);
  });
});

describe('sanitizeForDownstream', () => {
  const settings = () => ({
    $schema: 'https://json.schemastore.org/claude-code-settings.json',
    enabledPlugins: { 'commit-commands@claude-plugins-official': true },
    extraKnownMarketplaces: { mattpocock: { source: { source: 'git', url: 'https://example.com' } } },
    permissions: { allow: ['WebSearch'] },
    hooks: {
      SessionStart: [{ hooks: [{ type: 'command', command: 'agent-deck hook-handler', async: true }] }],
      Stop: [
        {
          matcher: '',
          hooks: [
            { type: 'command', command: 'python3 .claude/hooks/stop_test_verification.py' },
            { type: 'command', command: 'agent-deck hook-handler' },
          ],
        },
      ],
    },
  });

  test('leaves files other than .claude/settings.json untouched', () => {
    const content = Buffer.from('name: a\n');

    expect(sanitizeForDownstream('templates/workflows/claude.yml', content)).toBe(content);
  });

  test('drops host-only plugin state', () => {
    const result = JSON.parse(sanitizeForDownstream('.claude/settings.json', Buffer.from(JSON.stringify(settings()))));

    expect(result.enabledPlugins).toBeUndefined();
    expect(result.extraKnownMarketplaces).toBeUndefined();
    expect(result.permissions).toEqual({ allow: ['WebSearch'] });
  });

  test('drops hooks that call host-only commands but keeps the rest', () => {
    const result = JSON.parse(sanitizeForDownstream('.claude/settings.json', Buffer.from(JSON.stringify(settings()))));

    // agent-deck は downstream に存在しないため、実行するとセッションごとにエラーになる
    expect(result.hooks.SessionStart).toBeUndefined();
    expect(result.hooks.Stop[0].hooks).toEqual([
      { type: 'command', command: 'python3 .claude/hooks/stop_test_verification.py' },
    ]);
  });

  test('is stable so repeated syncs report unchanged', () => {
    const once = sanitizeForDownstream('.claude/settings.json', Buffer.from(JSON.stringify(settings())));
    const twice = sanitizeForDownstream('.claude/settings.json', once);

    expect(twice.equals(once)).toBe(true);
    expect(once.toString().endsWith('}\n')).toBe(true);
  });
});
