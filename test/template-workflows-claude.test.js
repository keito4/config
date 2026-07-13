'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');

/**
 * Read a workflow file from the repository.
 * @param {string} relativePath - Relative path from the repository root.
 * @returns {string} The workflow file content.
 */
function readWorkflow(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

/**
 * Check if a workflow file exists in the repository.
 * @param {string} relativePath - Relative path from the repository root.
 * @returns {boolean} True if the file exists.
 */
function workflowExists(relativePath) {
  return fs.existsSync(path.join(repoPath, relativePath));
}

describe('Template workflow contracts — sync check', () => {
  test('managed workflow templates are synchronized with actual workflows', () => {
    const output = execFileSync('node', ['script/check-workflow-template-sync.js'], {
      cwd: repoPath,
      encoding: 'utf8',
    });

    expect(output).toContain('workflow templates are synchronized');
  });
});

describe('claude-health-check.yml', () => {
  const workflowPath = 'templates/workflows/claude-health-check.yml';
  let workflow;

  beforeAll(() => {
    expect(workflowExists(workflowPath)).toBe(true);
    workflow = readWorkflow(workflowPath);
  });

  test('should be a valid workflow file with required top-level keys', () => {
    expect(workflow).toMatch(/^name:/m);
    expect(workflow).toContain('on:');
    expect(workflow).toContain('jobs:');
  });

  test('should have a weekly schedule trigger', () => {
    // Weekly cron: minute hour * * dayofweek (e.g. '0 0 * * 1' = Monday)
    expect(workflow).toContain('schedule:');
    expect(workflow).toMatch(/cron:.*\d+ \d+ \* \* \d+/);
  });

  test('should support manual dispatch via workflow_dispatch', () => {
    expect(workflow).toContain('workflow_dispatch:');
  });

  test('should use CLAUDE_CODE_OAUTH_TOKEN secret for authentication', () => {
    expect(workflow).toContain('CLAUDE_CODE_OAUTH_TOKEN');
  });

  test('should have timeout-minutes to prevent runaway jobs', () => {
    expect(workflow).toContain('timeout-minutes:');
  });

  test('should continue on error when checking token validity', () => {
    // Token check should not fail the workflow — it creates an issue instead
    expect(workflow).toContain('continue-on-error: true');
  });

  test('should create an issue when health check fails', () => {
    expect(workflow).toContain('gh issue create');
  });

  test('should deduplicate health check issues', () => {
    // Must check for existing open issues before creating new ones
    expect(workflow).toContain('gh issue list');
  });

  test('should have minimal top-level permissions (principle of least privilege)', () => {
    // Top-level permissions should be empty ({}) or not granting broad access
    expect(workflow).toContain('permissions: {}');
  });

  test('should grant issues: write permission at job level', () => {
    expect(workflow).toContain('issues: write');
  });

  test('should use the Anthropic claude-code-action', () => {
    expect(workflow).toContain('anthropics/claude-code-action');
  });

  test('should not contain hardcoded secrets or long tokens', () => {
    // No hardcoded credential patterns
    expect(workflow).not.toMatch(/token:\s*['"][A-Za-z0-9_-]{20,}['"]/);
    expect(workflow).not.toMatch(/api[_-]?key:\s*['"][A-Za-z0-9_-]{20,}['"]/);
  });
});
