#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');

// label-sync.yml is distributed as a reusable-workflow caller stub and is
// intentionally different from the runnable workflow (ADR 0018).
const syncPairs = [
  ['templates/workflows/claude.yml', '.github/workflows/claude.yml'],
  ['templates/workflows/dependabot-auto-merge.yml', '.github/workflows/dependabot-auto-merge.yml'],
  ['templates/workflows/quality-gate-fallback.yml', '.github/workflows/quality-gate-fallback.yml'],
  ['templates/workflows/scheduled-maintenance.yml', '.github/workflows/scheduled-maintenance.yml'],
];

/**
 * Normalize workflow YAML content for comparison.
 * Strips trailing whitespace, blank lines, and comment-only lines.
 *
 * @param {string} content - Raw workflow file content
 * @returns {string} Normalized content suitable for diffing
 */
function normalizeWorkflow(content) {
  return content
    .split(/\r?\n/)
    .map((line) => line.replace(/\s+$/u, ''))
    .filter((line) => {
      const trimmed = line.trim();
      return trimmed !== '' && !trimmed.startsWith('#');
    })
    .join('\n');
}

/**
 * Read a file relative to the repository root.
 *
 * @param {string} relativePath - Path relative to the repo root
 * @returns {string} File contents as UTF-8 string
 */
function readRelative(relativePath) {
  return fs.readFileSync(path.join(repoRoot, relativePath), 'utf8');
}

/**
 * Find the first differing line between two normalized workflow strings.
 *
 * @param {string} expected - Normalized content from the template file
 * @param {string} actual - Normalized content from the actual workflow file
 * @returns {{ line: number, expected: string, actual: string } | null}
 *   The first differing line info, or null if the strings are identical
 */
function firstDifference(expected, actual) {
  const expectedLines = expected.split('\n');
  const actualLines = actual.split('\n');
  const max = Math.max(expectedLines.length, actualLines.length);

  for (let index = 0; index < max; index += 1) {
    if (expectedLines[index] !== actualLines[index]) {
      return {
        line: index + 1,
        expected: expectedLines[index] ?? '<missing>',
        actual: actualLines[index] ?? '<missing>',
      };
    }
  }

  return null;
}

let hasDrift = false;

for (const [templatePath, actualPath] of syncPairs) {
  const templateFile = path.join(repoRoot, templatePath);
  const actualFile = path.join(repoRoot, actualPath);

  if (!fs.existsSync(templateFile) || !fs.existsSync(actualFile)) {
    console.error(`::error::Missing workflow sync pair: ${templatePath} -> ${actualPath}`);
    hasDrift = true;
    continue;
  }

  const expected = normalizeWorkflow(readRelative(templatePath));
  const actual = normalizeWorkflow(readRelative(actualPath));
  if (expected === actual) {
    continue;
  }

  const diff = firstDifference(expected, actual);
  console.error(`::error file=${templatePath}::Workflow template drift from ${actualPath}`);
  if (diff !== null) {
    console.error(`  first differing normalized line: ${diff.line}`);
    console.error(`  template: ${diff.expected}`);
    console.error(`  actual:   ${diff.actual}`);
  }
  hasDrift = true;
}

if (hasDrift) {
  console.error('workflow template sync check failed');
  process.exit(1);
}

console.log(`ok: ${syncPairs.length} workflow templates are synchronized`);
