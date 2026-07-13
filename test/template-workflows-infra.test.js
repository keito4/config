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

describe('label-sync.yml (reusable workflow and caller stub)', () => {
  const actualPath = '.github/workflows/label-sync.yml';
  const stubPath = 'templates/workflows/label-sync.yml';

  test.each([stubPath, actualPath])('%s: should trigger on push to main with .github/labels.yml changes', (wfPath) => {
    const workflow = readWorkflow(wfPath);
    expect(workflow).toContain('push:');
    expect(workflow).toContain('.github/labels.yml');
  });

  test.each([stubPath, actualPath])('%s: should support workflow_dispatch for manual sync', (wfPath) => {
    const workflow = readWorkflow(wfPath);
    expect(workflow).toContain('workflow_dispatch:');
  });

  test.each([stubPath, actualPath])('%s: should have checkout read and label write permissions', (wfPath) => {
    const workflow = readWorkflow(wfPath);
    expect(workflow).toContain('contents: read');
    expect(workflow).toContain('issues: write');
    expect(workflow).toContain('pull-requests: write');
  });

  test.each([stubPath, actualPath])('%s: should have concurrency control to prevent duplicate syncs', (wfPath) => {
    const workflow = readWorkflow(wfPath);
    expect(workflow).toContain('concurrency:');
  });

  test('actual workflow declares workflow_call with a config-file input', () => {
    const workflow = readWorkflow(actualPath);
    expect(workflow).toContain('workflow_call:');
    expect(workflow).toContain('config-file:');
    expect(workflow).toContain("config-file: ${{ inputs.config-file || '.github/labels.yml' }}");
  });

  test('actual workflow uses EndBug/label-sync with a timeout', () => {
    const workflow = readWorkflow(actualPath);
    expect(workflow).toContain('EndBug/label-sync');
    expect(workflow).toContain('timeout-minutes:');
  });

  test('stub calls the reusable workflow on main and carries the managed header', () => {
    const stub = readWorkflow(stubPath);
    expect(stub).toContain('uses: keito4/config/.github/workflows/label-sync.yml@main');
    expect(stub).toContain('# Managed by keito4/config');
    expect(stub).toContain('config-file: .github/labels.yml');
    expect(stub).not.toContain('EndBug/label-sync');
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
