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

describe('Template workflow contracts', () => {
  test('managed workflow templates are synchronized with actual workflows', () => {
    const output = execFileSync('node', ['script/check-workflow-template-sync.js'], {
      cwd: repoPath,
      encoding: 'utf8',
    });

    expect(output).toContain('workflow templates are synchronized');
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

  describe('dependabot-auto-merge.yml', () => {
    const workflowPath = 'templates/workflows/dependabot-auto-merge.yml';
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

    test('should use pull_request_target trigger (required for Dependabot secrets access)', () => {
      // pull_request_target is required so the workflow can access secrets
      // even when triggered by a fork (Dependabot PRs)
      expect(workflow).toContain('pull_request_target:');
    });

    test('should handle opened, synchronize, and reopened PR events', () => {
      expect(workflow).toContain('opened');
      expect(workflow).toContain('synchronize');
      expect(workflow).toContain('reopened');
    });

    test('should have concurrency control to prevent parallel runs', () => {
      expect(workflow).toContain('concurrency:');
      expect(workflow).toContain('cancel-in-progress: true');
    });

    test('should have timeout-minutes to prevent runaway jobs', () => {
      expect(workflow).toContain('timeout-minutes:');
    });

    test('should only run auto-merge job for Dependabot PRs', () => {
      expect(workflow).toContain("if: github.actor == 'dependabot[bot]'");
    });

    test('should fetch Dependabot metadata to determine update type', () => {
      expect(workflow).toContain('dependabot/fetch-metadata');
    });

    test('should auto-merge patch updates', () => {
      expect(workflow).toContain('version-update:semver-patch');
      expect(workflow).toContain('gh pr merge');
    });

    test('should label minor updates without auto-merging', () => {
      expect(workflow).toContain('version-update:semver-minor');
      expect(workflow).toContain('dependabot-minor');
    });

    test('should require manual review for major updates', () => {
      expect(workflow).toContain('version-update:semver-major');
      // Major updates get "needs-review" label, not auto-merged
      expect(workflow).toContain('needs-review');
    });

    test('should not auto-merge major updates', () => {
      // The major condition should not trigger gh pr merge
      expect(workflow).not.toMatch(/semver-major[\s\S]{0,300}gh pr merge/);
    });

    test('should have required permissions for merging PRs', () => {
      expect(workflow).toContain('permissions:');
      expect(workflow).toContain('contents: write');
      expect(workflow).toContain('issues: write');
      expect(workflow).toContain('pull-requests: write');
    });

    test('should use GITHUB_TOKEN (not a PAT) for operations', () => {
      expect(workflow).toContain('GITHUB_TOKEN');
      // Should not hardcode a token value
      expect(workflow).not.toMatch(/GH_TOKEN:\s*['"][A-Za-z0-9_-]{20,}['"]/);
    });
  });

  describe('dependabot-auto-merge.yml (template and actual — security-critical properties)', () => {
    const workflowPaths = [
      'templates/workflows/dependabot-auto-merge.yml',
      '.github/workflows/dependabot-auto-merge.yml',
    ];

    test.each(workflowPaths)(
      '%s: should gate the entire job on dependabot actor before write tokens are issued',
      (wfPath) => {
        // Job-level if guard prevents write-scoped GITHUB_TOKEN from being issued to non-Dependabot actors
        const workflow = readWorkflow(wfPath);
        expect(workflow).toContain("if: github.actor == 'dependabot[bot]'");
      },
    );

    test.each(workflowPaths)('%s: should restrict write permissions to job scope, not workflow scope', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      // Workflow-level: read-only fallback
      expect(workflow).toContain('contents: read');
      // Job-level: elevated only after actor is verified
      expect(workflow).toContain('contents: write');
      expect(workflow).toContain('issues: write');
      expect(workflow).toContain('pull-requests: write');
    });

    test.each(workflowPaths)('%s: should handle all semver update types', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('version-update:semver-patch');
      expect(workflow).toContain('version-update:semver-minor');
      expect(workflow).toContain('version-update:semver-major');
    });

    test.each(workflowPaths)('%s: should not auto-merge major updates', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).not.toMatch(/semver-major[\s\S]{0,300}gh pr merge/);
    });

    test.each(workflowPaths)('%s: should create labels before assigning them', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('gh label create "dependabot-minor"');
      expect(workflow).toContain('gh label create "needs-review"');
      expect(workflow).toContain('gh label create "breaking-change"');
    });
  });

  describe('quality-gate-fallback.yml (template and actual)', () => {
    const workflowPaths = [
      'templates/workflows/quality-gate-fallback.yml',
      '.github/workflows/quality-gate-fallback.yml',
    ];

    test.each(workflowPaths)('%s: job should be named "Quality Gate" (matches branch protection rule)', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('name: Quality Gate');
    });

    test.each(workflowPaths)('%s: should trigger on pull_request events', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('pull_request:');
    });

    test.each(workflowPaths)('%s: should have actions: read permission to query workflow runs', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('actions: read');
    });

    test.each(workflowPaths)('%s: should have timeout-minutes to prevent runaway jobs', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('timeout-minutes:');
    });

    test.each(workflowPaths)('%s: should have concurrency control', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('concurrency:');
    });

    test.each(workflowPaths)('%s: should check if CI workflow ran before emitting pass', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      // Uses ci_running output to decide whether to emit pass
      expect(workflow).toContain('ci_running');
    });

    test.each(workflowPaths)('%s: should only emit Quality Gate pass when CI is not running', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      // The "Pass" step should be conditional on ci_running being false
      expect(workflow).toMatch(/ci_running.*==.*false/);
    });

    test('template and actual should both emit "Quality Gate" job name', () => {
      const template = readWorkflow('templates/workflows/quality-gate-fallback.yml');
      const actual = readWorkflow('.github/workflows/quality-gate-fallback.yml');
      expect(template).toContain('name: Quality Gate');
      expect(actual).toContain('name: Quality Gate');
    });
  });

  describe('label-sync.yml (template and actual)', () => {
    const workflowPaths = ['templates/workflows/label-sync.yml', '.github/workflows/label-sync.yml'];

    test.each(workflowPaths)('%s: should trigger on push to main with .github/labels.yml changes', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('push:');
      expect(workflow).toContain('.github/labels.yml');
    });

    test.each(workflowPaths)('%s: should support workflow_dispatch for manual sync', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('workflow_dispatch:');
    });

    test.each(workflowPaths)('%s: should use EndBug/label-sync action', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('EndBug/label-sync');
    });

    test.each(workflowPaths)('%s: should have checkout read and label write permissions', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('contents: read');
      expect(workflow).toContain('issues: write');
      expect(workflow).toContain('pull-requests: write');
    });

    test.each(workflowPaths)('%s: should have concurrency control to prevent duplicate syncs', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('concurrency:');
    });

    test.each(workflowPaths)('%s: should have timeout-minutes', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('timeout-minutes:');
    });

    test.each(workflowPaths)('%s: should reference the labels config file', (wfPath) => {
      const workflow = readWorkflow(wfPath);
      expect(workflow).toContain('config-file:');
      expect(workflow).toContain('labels.yml');
    });

    test.each(['templates/github/labels.yml', '.github/labels.yml'])(
      '%s: should define labels used by dependabot auto-merge',
      (labelsPath) => {
        const labels = readWorkflow(labelsPath);
        expect(labels).toContain("name: 'dependabot-minor'");
        expect(labels).toContain("name: 'needs-review'");
        expect(labels).toContain("name: 'breaking-change'");
      },
    );

    test.each(['templates/github/labels.yml', '.github/labels.yml'])(
      '%s: should define all labels used by PR size check',
      (labelsPath) => {
        const labels = readWorkflow(labelsPath);
        for (const size of ['XS', 'S', 'M', 'L', 'XL']) {
          expect(labels).toContain(`name: 'size/${size}'`);
        }
      },
    );
  });
});
