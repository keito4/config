const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');

function runRequiredWorkflowScript(workflows) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'required-workflow-test-'));

  try {
    const workflowsDir = path.join(tempRoot, '.github', 'workflows');
    fs.mkdirSync(workflowsDir, { recursive: true });
    for (const [filename, content] of Object.entries(workflows)) {
      fs.writeFileSync(path.join(workflowsDir, filename), content);
    }

    const scriptPath = path.join(repoPath, 'script', 'repo-maintenance.sh');
    try {
      return execFileSync('bash', [scriptPath, '--check-required-workflows'], {
        cwd: tempRoot,
        encoding: 'utf8',
      });
    } catch (error) {
      return `${error.stdout || ''}${error.stderr || ''}`;
    }
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

describe('Required workflow trigger compatibility', () => {
  test('repo-maintenance flags .yaml required workflows without push or pull_request', () => {
    const output = runRequiredWorkflowScript({
      'security-summary.yaml': `
name: Security Summary
on:
  schedule:
    - cron: '0 0 * * 1'
  workflow_dispatch:

jobs:
  generate-summary:
    runs-on: ubuntu-latest
    steps:
      - run: npm audit --audit-level=high
`,
    });

    expect(output).toContain('security-summary.yaml: Required Workflow 候補ですが push / pull_request');
    expect(output).toContain('security-summary.yaml: Slack 通知付き generate-summary は job-level if');
  });

  test('repo-maintenance detects security summary by filename without name key', () => {
    const output = runRequiredWorkflowScript({
      'security-summary.yml': `
on:
  workflow_dispatch:

jobs:
  generate-summary:
    runs-on: ubuntu-latest
    steps:
      - run: echo summary
`,
    });

    expect(output).toContain('security-summary.yml: Required Workflow 候補ですが push / pull_request');
    expect(output).toContain('security-summary.yml: Slack 通知付き generate-summary は job-level if');
  });

  test('repo-maintenance continues after unnamed unrelated workflow files', () => {
    const output = runRequiredWorkflowScript({
      'aaa.yml': `
on:
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo unrelated
`,
      'security-summary.yml': `
name: Security Summary
on:
  workflow_dispatch:

jobs:
  generate-summary:
    runs-on: ubuntu-latest
    steps:
      - run: echo summary
`,
    });

    expect(output).toContain('security-summary.yml: Required Workflow 候補ですが push / pull_request');
    expect(output).toContain('security-summary.yml: Slack 通知付き generate-summary は job-level if');
  });

  test('repo-maintenance only treats push and pull_request under on as triggers', () => {
    const output = runRequiredWorkflowScript({
      'required.yml': `
name: Required Workflow
on:
  schedule:
    - cron: '0 0 * * 1'

jobs:
  push:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
`,
    });

    expect(output).toContain('required.yml: Required Workflow 候補ですが push / pull_request');
  });

  test('repo-maintenance accepts guarded security summary required workflow', () => {
    const output = runRequiredWorkflowScript({
      'security-summary.yml': `
name: Security Summary
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 0 * * 1'
  workflow_dispatch:

jobs:
  dependency-audit:
    runs-on: ubuntu-latest
    steps:
      - run: npm audit --audit-level=high
  generate-summary:
    if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
    runs-on: ubuntu-latest
    steps:
      - run: echo summary
`,
    });

    expect(output.trim()).toBe('');
  });

  test('repo-maintenance accepts block sequence event syntax', () => {
    const output = runRequiredWorkflowScript({
      'required.yml': `
name: Required Workflow
on:
  - push
  - pull_request

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
`,
    });

    expect(output.trim()).toBe('');
  });

  test('repo-maintenance does not treat pull_request_target as pull_request', () => {
    const output = runRequiredWorkflowScript({
      'required.yml': `
name: Required Workflow
on: [pull_request_target, pull_request_review]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
`,
    });

    expect(output).toContain('required.yml: Required Workflow 候補ですが push / pull_request');
  });

  test('repo-maintenance accepts single-quoted on key', () => {
    const output = runRequiredWorkflowScript({
      'required.yml': `
name: Required Workflow
'on': [push]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo ok
`,
    });

    expect(output.trim()).toBe('');
  });
});
