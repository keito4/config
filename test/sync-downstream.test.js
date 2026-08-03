'use strict';

/**
 * Tests for script/sync-downstream.js — the downstream template sync engine.
 *
 * Covers manifest schema validation and per-repo file resolution (groups +
 * exclude).  File sync behaviour and settings sanitization are tested in
 * sync-downstream-sync.test.js.
 */

const fs = require('fs');
const path = require('path');

const {
  isIgnored,
  loadManifest,
  validateManifest,
  resolveFilesForRepo,
  listSourceFiles,
  parseArgs,
} = require('../script/sync-downstream');

const repoRoot = path.resolve(__dirname, '..');

function validManifest() {
  return {
    groups: {
      'claude-config': [{ source: '.claude/hooks/', target: '.claude/hooks/' }],
      'workflow-claude': [{ source: 'templates/workflows/claude.yml', target: '.github/workflows/claude.yml' }],
    },
    repos: [{ name: 'keito4/example', groups: ['claude-config'] }],
  };
}

describe('validateManifest', () => {
  test('accepts a well-formed manifest', () => {
    expect(() => validateManifest(validManifest())).not.toThrow();
  });

  test('rejects a manifest without groups', () => {
    expect(() => validateManifest({ repos: [] })).toThrow(/"groups" object is required/u);
  });

  test('rejects a manifest without repos', () => {
    expect(() => validateManifest({ groups: {} })).toThrow(/"repos" array is required/u);
  });

  test('rejects an empty group', () => {
    const manifest = validManifest();
    manifest.groups['claude-config'] = [];
    expect(() => validateManifest(manifest)).toThrow(/non-empty array/u);
  });

  test('rejects a group entry without source/target', () => {
    const manifest = validManifest();
    manifest.groups['claude-config'] = [{ source: '.claude/hooks/' }];
    expect(() => validateManifest(manifest)).toThrow(/without source\/target/u);
  });

  test('rejects a null group entry', () => {
    const manifest = validManifest();
    manifest.groups['claude-config'] = [null];
    expect(() => validateManifest(manifest)).toThrow(/without source\/target/u);
  });

  test('rejects a non-object group entry', () => {
    const manifest = validManifest();
    manifest.groups['claude-config'] = ['.claude/hooks/'];
    expect(() => validateManifest(manifest)).toThrow(/without source\/target/u);
  });

  test('rejects an invalid repo name', () => {
    const manifest = validManifest();
    manifest.repos[0].name = 'not-a-repo';
    expect(() => validateManifest(manifest)).toThrow(/invalid repo name/u);
  });

  test('rejects a null repo entry', () => {
    const manifest = validManifest();
    manifest.repos = [null];
    expect(() => validateManifest(manifest)).toThrow(/invalid repo entry/u);
  });

  test('rejects a non-object repo entry', () => {
    const manifest = validManifest();
    manifest.repos = ['keito4/example'];
    expect(() => validateManifest(manifest)).toThrow(/invalid repo entry/u);
  });

  test('rejects a repo without groups', () => {
    const manifest = validManifest();
    manifest.repos[0].groups = [];
    expect(() => validateManifest(manifest)).toThrow(/at least one group/u);
  });

  test('rejects a repo referencing an unknown group', () => {
    const manifest = validManifest();
    manifest.repos[0].groups = ['does-not-exist'];
    expect(() => validateManifest(manifest)).toThrow(/unknown group/u);
  });

  test('accepts a repo with a valid exclude list', () => {
    const manifest = validManifest();
    manifest.repos[0].exclude = ['.claude/hooks/common.py'];
    expect(() => validateManifest(manifest)).not.toThrow();
  });

  test('rejects a repo whose exclude list is not an array', () => {
    const manifest = validManifest();
    manifest.repos[0].exclude = '.claude/hooks/common.py';
    expect(() => validateManifest(manifest)).toThrow(/"exclude" must be an array of strings/u);
  });

  test('rejects a repo whose exclude list contains a non-string entry', () => {
    const manifest = validManifest();
    manifest.repos[0].exclude = [42];
    expect(() => validateManifest(manifest)).toThrow(/"exclude" must be an array of strings/u);
  });
});

describe('checked-in manifest (.github/sync-downstream.json)', () => {
  const manifest = loadManifest();

  test('passes schema validation on load', () => {
    expect(manifest.repos.length).toBeGreaterThan(0);
  });

  test('every group source exists in this repository', () => {
    for (const entries of Object.values(manifest.groups)) {
      for (const entry of entries) {
        expect(fs.existsSync(path.join(repoRoot, entry.source))).toBe(true);
      }
    }
  });

  test('every repo resolves to at least one syncable file', () => {
    for (const repo of manifest.repos) {
      const resolved = resolveFilesForRepo(manifest, repo.name);
      const files = resolved.entries.flatMap((entry) => listSourceFiles(repoRoot, entry));
      expect(files.length).toBeGreaterThan(0);
    }
  });
});

describe('resolveFilesForRepo', () => {
  test('merges entries from all opted-in groups', () => {
    const manifest = validManifest();
    manifest.repos[0].groups = ['claude-config', 'workflow-claude'];
    const resolved = resolveFilesForRepo(manifest, 'keito4/example');
    expect(resolved.entries).toHaveLength(2);
    expect(resolved.exclude.size).toBe(0);
  });

  test('exposes the per-repo exclude list as a set', () => {
    const manifest = validManifest();
    manifest.repos[0].exclude = ['.claude/hooks/common.py'];
    const resolved = resolveFilesForRepo(manifest, 'keito4/example');
    expect(resolved.exclude.has('.claude/hooks/common.py')).toBe(true);
  });

  test('throws for a repo that is not in the manifest', () => {
    expect(() => resolveFilesForRepo(validManifest(), 'keito4/unknown')).toThrow(/unknown repo/u);
  });
});

describe('isIgnored', () => {
  test.each([
    ['.claude/hooks/__pycache__/common.cpython-312.pyc', true],
    ['.claude/hooks/common.pyc', true],
    ['__pycache__/x.py', true],
    ['.claude/hooks/common.py', false],
    ['templates/workflows/claude.yml', false],
  ])('%s -> %s', (relativePath, expected) => {
    expect(isIgnored(relativePath)).toBe(expected);
  });
});

describe('parseArgs', () => {
  test('parses repo, target, and check flag', () => {
    const args = parseArgs(['--repo', 'keito4/ohana', '--target', '/tmp/x', '--check']);
    expect(args).toEqual({ repo: 'keito4/ohana', target: '/tmp/x', check: true });
  });

  test('rejects unknown flags', () => {
    expect(() => parseArgs(['--force'])).toThrow(/unknown argument/u);
  });
});
