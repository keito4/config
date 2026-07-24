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
