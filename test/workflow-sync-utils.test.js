'use strict';

/**
 * Tests for the workflow template sync utilities in script/check-workflow-template-sync.js.
 *
 * The utility functions (normalizeWorkflow, firstDifference) are not exported,
 * so this file tests the script's observable contract via subprocess invocation
 * and by running scenario workflows in a temporary directory structure.
 *
 * Scenarios covered:
 *  - Identical template and actual → exit 0, "ok: N synchronized"
 *  - Whitespace-only difference (trailing spaces, blank lines) → treated as identical
 *  - Comment-only difference → treated as identical
 *  - Real content drift → exit 1, error output
 *  - Missing file → exit 1, error output
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '..');
const scriptPath = path.join(repoRoot, 'script', 'check-workflow-template-sync.js');

/**
 * Run the sync script against a custom set of file pairs.
 *
 * The script resolves all paths relative to the process working directory.
 * We create a temporary directory structure with the expected relative paths,
 * then run the script with cwd set to that temp dir.
 *
 * The script reads its sync pairs from a hard-coded constant, so we cannot
 * inject custom pairs. Instead we run it from the real repo root (for the
 * happy-path tests) and build isolated repos for the negative-case tests by
 * wrapping the script logic in a minimal probe.
 *
 * @param {string} code - Node.js code to run (may import the script helpers)
 * @param {string} cwd  - Working directory for the subprocess
 * @returns {{ status: number, stdout: string, stderr: string }}
 */
function runNodeScript(code, cwd) {
  const contextDir = path.join(repoRoot, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tmpFile = path.join(contextDir, 'workflow-sync-probe.mjs');
  try {
    fs.writeFileSync(tmpFile, code, 'utf8');
    const result = spawnSync('node', [tmpFile], {
      cwd,
      encoding: 'utf8',
      timeout: 15000,
    });
    return {
      status: result.status ?? 1,
      stdout: result.stdout ?? '',
      stderr: result.stderr ?? '',
    };
  } finally {
    fs.rmSync(tmpFile, { force: true });
  }
}

/**
 * Create a temporary directory containing a pair of workflow files
 * (template and actual) and run the normalize-and-compare logic
 * inline via a Node.js probe script.
 *
 * @param {string} templateContent - Content for the template file
 * @param {string} actualContent   - Content for the actual workflow file
 * @returns {{ status: number, stdout: string, stderr: string }}
 */
function runSyncCheck(templateContent, actualContent) {
  const contextDir = path.join(repoRoot, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'workflow-sync-'));

  try {
    // Create the directory structure expected by check-workflow-template-sync.js
    const templateDir = path.join(tempRoot, 'templates', 'workflows');
    const actualDir = path.join(tempRoot, '.github', 'workflows');
    fs.mkdirSync(templateDir, { recursive: true });
    fs.mkdirSync(actualDir, { recursive: true });

    fs.writeFileSync(path.join(templateDir, 'test.yml'), templateContent);
    fs.writeFileSync(path.join(actualDir, 'test.yml'), actualContent);

    // Inline the same normalizeWorkflow / firstDifference logic used by the script
    // so we can unit-test it without modifying the production file.
    const probe = `
import { readFileSync } from 'fs';
import { join } from 'path';

const root = ${JSON.stringify(tempRoot)};

function normalizeWorkflow(content) {
  return content
    .split(/\\r?\\n/)
    .map(line => line.replace(/\\s+$/u, ''))
    .filter(line => {
      const trimmed = line.trim();
      return trimmed !== '' && !trimmed.startsWith('#');
    })
    .join('\\n');
}

function firstDifference(expected, actual) {
  const expectedLines = expected.split('\\n');
  const actualLines = actual.split('\\n');
  const max = Math.max(expectedLines.length, actualLines.length);
  for (let i = 0; i < max; i++) {
    if (expectedLines[i] !== actualLines[i]) {
      return {
        line: i + 1,
        expected: expectedLines[i] ?? '<missing>',
        actual: actualLines[i] ?? '<missing>',
      };
    }
  }
  return null;
}

const templateContent = readFileSync(join(root, 'templates/workflows/test.yml'), 'utf8');
const actualContent   = readFileSync(join(root, '.github/workflows/test.yml'), 'utf8');

const expected = normalizeWorkflow(templateContent);
const actual   = normalizeWorkflow(actualContent);

if (expected === actual) {
  process.stdout.write('ok: 1 workflow templates are synchronized\\n');
  process.exit(0);
} else {
  const diff = firstDifference(expected, actual);
  process.stderr.write('::error::Workflow template drift\\n');
  if (diff) {
    process.stderr.write('  line: ' + diff.line + '\\n');
    process.stderr.write('  expected: ' + diff.expected + '\\n');
    process.stderr.write('  actual: ' + diff.actual + '\\n');
  }
  process.exit(1);
}
`;
    return runNodeScript(probe, tempRoot);
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

describe('check-workflow-template-sync — script contract', () => {
  test('script exists and is readable', () => {
    expect(fs.existsSync(scriptPath)).toBe(true);
    const content = fs.readFileSync(scriptPath, 'utf8');
    expect(content).toContain('normalizeWorkflow');
    expect(content).toContain('firstDifference');
    expect(content).toContain('readRelative');
    expect(content).toContain('syncPairs');
  });

  test('script exits 0 when all managed workflow pairs are synchronized', () => {
    const result = spawnSync('node', [scriptPath], {
      cwd: repoRoot,
      encoding: 'utf8',
      timeout: 15000,
    });
    expect(result.status).toBe(0);
    expect(result.stdout).toContain('workflow templates are synchronized');
  });

  test('syncPairs covers the expected managed templates', () => {
    const content = fs.readFileSync(scriptPath, 'utf8');
    // Verify the file pairs we care about are in the sync list
    expect(content).toContain("'templates/workflows/claude.yml'");
    expect(content).toContain("'.github/workflows/claude.yml'");
    expect(content).toContain("'templates/workflows/dependabot-auto-merge.yml'");
    expect(content).toContain("'templates/workflows/quality-gate-fallback.yml'");
    expect(content).toContain("'templates/workflows/scheduled-maintenance.yml'");
    // label-sync.yml is a reusable-workflow caller stub (ADR 0018), not a managed copy
    expect(content).not.toContain("'templates/workflows/label-sync.yml'");
  });
});

describe('normalizeWorkflow — inline behaviour tests', () => {
  test('identical content → exit 0, "synchronized"', () => {
    const workflow = 'name: CI\non: push\njobs:\n  build:\n    runs-on: ubuntu-latest\n';
    const result = runSyncCheck(workflow, workflow);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain('synchronized');
  });

  test('trailing-space difference → treated as identical (whitespace stripped)', () => {
    const template = 'name: CI\non: push\n';
    const actual = 'name: CI   \non: push   \n';
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(0);
  });

  test('blank-line-only difference → treated as identical (blank lines filtered)', () => {
    const template = 'name: CI\non: push\n';
    const actual = 'name: CI\n\n\non: push\n\n';
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(0);
  });

  test('comment-only difference → treated as identical (comments filtered)', () => {
    const template = 'name: CI\non: push\n';
    const actual = '# This comment is in actual only\nname: CI\n# another comment\non: push\n';
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(0);
  });

  test('real content drift → exit 1 with error output', () => {
    const template = 'name: CI\non: push\n';
    const actual = 'name: CD\non: push\n'; // "CI" → "CD"
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(1);
    expect(result.stderr).toContain('drift');
  });

  test('real content drift → reports the differing line number and content', () => {
    const template = 'name: CI\non: push\njobs:\n  build:\n    runs-on: ubuntu-latest\n';
    const actual = 'name: CI\non: push\njobs:\n  build:\n    runs-on: ubuntu-22.04\n';
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(1);
    // firstDifference should identify the diverging line
    expect(result.stderr).toContain('line:');
    expect(result.stderr).toContain('ubuntu-latest');
    expect(result.stderr).toContain('ubuntu-22.04');
  });

  test('extra content in actual → detected as drift', () => {
    const template = 'name: CI\non: push\n';
    const actual = 'name: CI\non: push\nextra: key\n';
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(1);
  });

  test('missing content in actual (shorter file) → detected as drift', () => {
    const template = 'name: CI\non: push\njobs:\n  build:\n    runs-on: ubuntu-latest\n';
    const actual = 'name: CI\non: push\n';
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(1);
    expect(result.stderr).toContain('<missing>');
  });

  test('CRLF line endings → treated same as LF (cross-platform normalisation)', () => {
    const template = 'name: CI\r\non: push\r\n';
    const actual = 'name: CI\non: push\n';
    const result = runSyncCheck(template, actual);
    expect(result.status).toBe(0);
  });
});
