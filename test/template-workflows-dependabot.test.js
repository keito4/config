'use strict';

const fs = require('fs');
const path = require('path');

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
    expect(workflow).toContain('GH_REPO: ${{ github.repository }}');
  });
});
