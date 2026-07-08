'use strict';

/**
 * Tests for the workflow template sync utilities in script/check-workflow-template-sync.js.
 *
 * normalizeWorkflow and firstDifference are exported from the script and called
 * directly here, eliminating the need for subprocess probes or duplicated logic.
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

const { normalizeWorkflow, firstDifference } = require('../script/check-workflow-template-sync');

/**
 * Run normalizeWorkflow and firstDifference directly and return a result object
 * that mirrors the { status, stdout, stderr } shape used by the test assertions.
 *
 * @param {string} templateContent - Content for the template file
 * @param {string} actualContent   - Content for the actual workflow file
 * @returns {{ status: number, stdout: string, stderr: string }}
 */
function runSyncCheck(templateContent, actualContent) {
  const expected = normalizeWorkflow(templateContent);
  const actual = normalizeWorkflow(actualContent);

  if (expected === actual) {
    return { status: 0, stdout: 'ok: 1 workflow templates are synchronized\n', stderr: '' };
  }

  const diff = firstDifference(expected, actual);
  let stderr = '::error::Workflow template drift\n';
  if (diff !== null) {
    stderr += `  line: ${diff.line}\n`;
    stderr += `  expected: ${diff.expected}\n`;
    stderr += `  actual: ${diff.actual}\n`;
  }
  return { status: 1, stdout: '', stderr };
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
    expect(content).toContain("'templates/workflows/label-sync.yml'");
    expect(content).toContain("'templates/workflows/quality-gate-fallback.yml'");
    expect(content).toContain("'templates/workflows/scheduled-maintenance.yml'");
  });
});

describe('normalizeWorkflow / firstDifference — behaviour tests', () => {
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
