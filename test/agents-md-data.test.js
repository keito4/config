'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// script/lib/agents-md-data.sh feeds the AUTO-GENERATED tables in AGENTS.md / CLAUDE.md
// (Hooks, .claude subdirectories, Quality Gates). It is plain bash data with no direct
// test coverage of its own — drift between this file and the actual repository state
// (e.g. a new hook added without updating HOOK_TABLE) would silently produce stale or
// incomplete documentation. These tests source the file in a subshell and assert its
// data stays consistent with the filesystem and with itself.

const repoPath = path.resolve(__dirname, '..');
const dataScript = path.join(repoPath, 'script', 'lib', 'agents-md-data.sh');
const hooksDir = path.join(repoPath, '.claude', 'hooks');
const claudeDir = path.join(repoPath, '.claude');

const SECTION_MARKER = '===SECTION===';

/**
 * Sources agents-md-data.sh and dumps the arrays this suite cares about as
 * newline-separated sections, so they can be inspected from plain JS.
 * @returns {{HOOK_TABLE: string[], CLAUDE_SUB_ORDER: string[], CLAUDE_SUB_PURPOSE_KEYS: string[], QG_ORDER: string[], QG_PURPOSE_KEYS: string[]}}
 */
function loadAgentsMdData() {
  const dumpScript = `
    set -euo pipefail
    source "${dataScript}"
    echo "${SECTION_MARKER}HOOK_TABLE"
    printf '%s\\n' "\${HOOK_TABLE[@]}"
    echo "${SECTION_MARKER}CLAUDE_SUB_ORDER"
    printf '%s\\n' "\${CLAUDE_SUB_ORDER[@]}"
    echo "${SECTION_MARKER}CLAUDE_SUB_PURPOSE_KEYS"
    printf '%s\\n' "\${!CLAUDE_SUB_PURPOSE[@]}"
    echo "${SECTION_MARKER}QG_ORDER"
    printf '%s\\n' "\${QG_ORDER[@]}"
    echo "${SECTION_MARKER}QG_PURPOSE_KEYS"
    printf '%s\\n' "\${!QG_PURPOSE[@]}"
  `;

  const result = spawnSync('bash', ['-c', dumpScript], { cwd: repoPath, encoding: 'utf8' });
  if (result.status !== 0) {
    throw new Error(`Failed to source agents-md-data.sh: ${result.stderr}`);
  }

  const sections = {};
  let current = null;
  for (const line of result.stdout.split('\n')) {
    if (line.startsWith(SECTION_MARKER)) {
      current = line.slice(SECTION_MARKER.length);
      sections[current] = [];
      continue;
    }
    if (current && line.length > 0) {
      sections[current].push(line);
    }
  }
  return sections;
}

describe('script/lib/agents-md-data.sh', () => {
  let data;

  beforeAll(() => {
    data = loadAgentsMdData();
  });

  describe('HOOK_TABLE', () => {
    test('every entry has filename|trigger|purpose with no empty field', () => {
      for (const entry of data.HOOK_TABLE) {
        const fields = entry.split('|');
        expect(fields).toHaveLength(3);
        for (const field of fields) {
          expect(field.trim().length).toBeGreaterThan(0);
        }
      }
    });

    test('lists exactly the .py files present in .claude/hooks/ (no missing, no stale entries)', () => {
      const actualHooks = fs
        .readdirSync(hooksDir)
        .filter((f) => f.endsWith('.py'))
        .sort();
      const tableHooks = data.HOOK_TABLE.map((entry) => entry.split('|')[0]).sort();

      expect(tableHooks).toEqual(actualHooks);
    });

    test('has no duplicate filenames', () => {
      const names = data.HOOK_TABLE.map((entry) => entry.split('|')[0]);
      expect(new Set(names).size).toBe(names.length);
    });
  });

  describe('CLAUDE_SUB_ORDER / CLAUDE_SUB_PURPOSE', () => {
    test('CLAUDE_SUB_ORDER and CLAUDE_SUB_PURPOSE cover the same set of keys', () => {
      expect([...data.CLAUDE_SUB_ORDER].sort()).toEqual([...data.CLAUDE_SUB_PURPOSE_KEYS].sort());
    });

    test('CLAUDE_SUB_ORDER has no duplicate entries', () => {
      expect(new Set(data.CLAUDE_SUB_ORDER).size).toBe(data.CLAUDE_SUB_ORDER.length);
    });

    test('matches the actual subdirectories under .claude/', () => {
      const actualSubDirs = fs
        .readdirSync(claudeDir, { withFileTypes: true })
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .sort();

      expect([...data.CLAUDE_SUB_ORDER].sort()).toEqual(actualSubDirs);
    });
  });

  describe('QG_ORDER / QG_PURPOSE', () => {
    test('QG_ORDER and QG_PURPOSE cover the same set of keys', () => {
      expect([...data.QG_ORDER].sort()).toEqual([...data.QG_PURPOSE_KEYS].sort());
    });

    test('QG_ORDER has no duplicate entries', () => {
      expect(new Set(data.QG_ORDER).size).toBe(data.QG_ORDER.length);
    });
  });
});
