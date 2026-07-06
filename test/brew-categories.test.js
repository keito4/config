'use strict';

/**
 * Tests for script/lib/brew_categories.py
 *
 * Exercises the CLI interface and core logic via subprocess:
 *  - CLI argument validation (help, missing required args)
 *  - Exact, prefix, and regex item matching
 *  - Brew-format output (brew/cask keyword)
 *  - Human-format output (section headers, uncategorized label)
 *  - Items not matched by any category go to Uncategorized
 *  - Missing manifest file exits non-zero
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const scriptPath = path.join(repoPath, 'script', 'lib', 'brew_categories.py');
const contextDir = path.join(repoPath, '.context');

/**
 * Run brew_categories.py with the given args and stdin input.
 * @param {string[]} args
 * @param {string} [stdin]
 * @returns {{ status: number, stdout: string, stderr: string }}
 */
function runScript(args, stdin = '') {
  const result = spawnSync('python3', [scriptPath, ...args], {
    cwd: repoPath,
    input: stdin,
    encoding: 'utf8',
    timeout: 10000,
  });
  return {
    status: result.status ?? 1,
    stdout: result.stdout ?? '',
    stderr: result.stderr ?? '',
  };
}

/**
 * Write a temporary manifest JSON file under .context/ and invoke callback.
 * The file is removed after the callback returns.
 * @param {object} categories - Object to serialize as JSON manifest
 * @param {(manifestPath: string) => void} callback
 */
function withTempManifest(categories, callback) {
  fs.mkdirSync(contextDir, { recursive: true });
  const manifestPath = path.join(contextDir, 'brew-categories-test-manifest.json');
  try {
    fs.writeFileSync(manifestPath, JSON.stringify(categories));
    callback(manifestPath);
  } finally {
    fs.rmSync(manifestPath, { force: true });
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Script existence and CLI argument validation
// ──────────────────────────────────────────────────────────────────────────────
describe('brew_categories.py — script existence and CLI', () => {
  test('script exists at expected path', () => {
    expect(fs.existsSync(scriptPath)).toBe(true);
  });

  test('script has shebang line', () => {
    const content = fs.readFileSync(scriptPath, 'utf8');
    expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
  });

  test('--help exits 0 and mentions required flags', () => {
    const result = runScript(['--help']);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain('--manifest');
    expect(result.stdout).toContain('--type');
    expect(result.stdout).toContain('--format');
  });

  test('omitting --manifest exits non-zero', () => {
    const result = runScript(['--type', 'formulae']);
    expect(result.status).not.toBe(0);
  });

  test('omitting --type exits non-zero', () => {
    withTempManifest({ formulae: [] }, (manifestPath) => {
      const result = runScript(['--manifest', manifestPath]);
      expect(result.status).not.toBe(0);
    });
  });

  test('non-existent manifest file exits non-zero', () => {
    const result = runScript(['--manifest', '/nonexistent/manifest.json', '--type', 'formulae']);
    expect(result.status).not.toBe(0);
  });
});

// ──────────────────────────────────────────────────────────────────────────────
// Brew-format output
// ──────────────────────────────────────────────────────────────────────────────
describe('brew_categories.py — brew format output', () => {
  test('exact match categorizes item under correct section', () => {
    const manifest = {
      formulae: [
        {
          id: 'vcs',
          title: 'Version Control',
          match: { exact: ['git', 'gh'] },
        },
      ],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(
        ['--manifest', manifestPath, '--type', 'formulae', '--format', 'brew'],
        'git\ngh\nnvim\n',
      );
      expect(result.status).toBe(0);
      expect(result.stdout).toContain('# Version Control');
      expect(result.stdout).toContain('brew "git"');
      expect(result.stdout).toContain('brew "gh"');
    });
  });

  test('unmatched items appear in Uncategorized section', () => {
    const manifest = {
      formulae: [{ id: 'vcs', title: 'VCS', match: { exact: ['git'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(['--manifest', manifestPath, '--type', 'formulae', '--format', 'brew'], 'git\nnvim\n');
      expect(result.status).toBe(0);
      expect(result.stdout).toContain('# Uncategorized');
      expect(result.stdout).toContain('brew "nvim"');
    });
  });

  test('casks type uses "cask" keyword instead of "brew"', () => {
    const manifest = {
      casks: [{ id: 'browsers', title: 'Browsers', match: { exact: ['firefox'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(['--manifest', manifestPath, '--type', 'casks', '--format', 'brew'], 'firefox\n');
      expect(result.status).toBe(0);
      expect(result.stdout).toContain('cask "firefox"');
      expect(result.stdout).not.toContain('brew "firefox"');
    });
  });

  test('prefix matching groups items sharing a common prefix', () => {
    const manifest = {
      formulae: [{ id: 'lua', title: 'Lua Toolchain', match: { prefix: ['lua'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(
        ['--manifest', manifestPath, '--type', 'formulae', '--format', 'brew'],
        'lua\nluarocks\ngit\n',
      );
      expect(result.status).toBe(0);
      expect(result.stdout).toContain('# Lua Toolchain');
      expect(result.stdout).toContain('brew "lua"');
      expect(result.stdout).toContain('brew "luarocks"');
    });
  });

  test('regex matching groups items matching a pattern', () => {
    const manifest = {
      formulae: [{ id: 'go', title: 'Go', match: { regex: ['^go(@[0-9])?$'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(
        ['--manifest', manifestPath, '--type', 'formulae', '--format', 'brew'],
        'go\ngo@1\ngit\n',
      );
      expect(result.status).toBe(0);
      expect(result.stdout).toContain('brew "go"');
      expect(result.stdout).toContain('brew "go@1"');
    });
  });

  test('each item is only assigned to the first matching category', () => {
    const manifest = {
      formulae: [
        { id: 'first', title: 'First', match: { exact: ['curl'] } },
        { id: 'second', title: 'Second', match: { exact: ['curl'] } },
      ],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(['--manifest', manifestPath, '--type', 'formulae', '--format', 'brew'], 'curl\n');
      expect(result.status).toBe(0);
      // curl should only appear once (in the first matching section)
      const brewCurlMatches = (result.stdout.match(/brew "curl"/g) || []).length;
      expect(brewCurlMatches).toBe(1);
    });
  });

  test('empty stdin produces no item output', () => {
    const manifest = {
      formulae: [{ id: 'tools', title: 'Tools', match: { exact: ['git'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(['--manifest', manifestPath, '--type', 'formulae', '--format', 'brew'], '');
      expect(result.status).toBe(0);
      expect(result.stdout).not.toContain('brew "');
    });
  });
});

// ──────────────────────────────────────────────────────────────────────────────
// Human-format output
// ──────────────────────────────────────────────────────────────────────────────
describe('brew_categories.py — human format output', () => {
  test('uses === Title === section headers', () => {
    const manifest = {
      formulae: [{ id: 'cli', title: 'CLI Tools', match: { exact: ['ripgrep', 'fd'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(
        ['--manifest', manifestPath, '--type', 'formulae', '--format', 'human'],
        'ripgrep\nfd\n',
      );
      expect(result.status).toBe(0);
      expect(result.stdout).toContain('=== CLI Tools ===');
      expect(result.stdout).toContain('ripgrep');
      expect(result.stdout).toContain('fd');
    });
  });

  test('--label-uncategorized shows Uncategorized section for unmatched items', () => {
    const manifest = {
      formulae: [{ id: 'tools', title: 'Tools', match: { exact: ['git'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(
        ['--manifest', manifestPath, '--type', 'formulae', '--format', 'human', '--label-uncategorized'],
        'git\nnvim\n',
      );
      expect(result.status).toBe(0);
      expect(result.stdout).toContain('=== Uncategorized ===');
      expect(result.stdout).toContain('nvim');
    });
  });

  test('does not show Uncategorized section without --label-uncategorized', () => {
    const manifest = {
      formulae: [{ id: 'tools', title: 'Tools', match: { exact: ['git'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(['--manifest', manifestPath, '--type', 'formulae', '--format', 'human'], 'git\nnvim\n');
      expect(result.status).toBe(0);
      expect(result.stdout).not.toContain('=== Uncategorized ===');
    });
  });

  test('does not emit brew/cask keyword lines in human format', () => {
    const manifest = {
      formulae: [{ id: 'tools', title: 'Tools', match: { exact: ['git'] } }],
    };
    withTempManifest(manifest, (manifestPath) => {
      const result = runScript(['--manifest', manifestPath, '--type', 'formulae', '--format', 'human'], 'git\n');
      expect(result.status).toBe(0);
      expect(result.stdout).not.toMatch(/^brew "/m);
      expect(result.stdout).not.toMatch(/^cask "/m);
    });
  });
});
