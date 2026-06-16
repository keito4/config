const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');

function readWorkflow(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

function extractRequiredWorkflowScript(command) {
  const sectionStart = command.indexOf('### 3.5.2.1 Required Workflow Trigger Compatibility Check');
  expect(sectionStart).toBeGreaterThanOrEqual(0);

  const bashStart = command.indexOf('```bash', sectionStart);
  expect(bashStart).toBeGreaterThanOrEqual(0);

  const codeStart = bashStart + '```bash\n'.length;
  const codeEnd = command.indexOf('```', codeStart);
  expect(codeEnd).toBeGreaterThan(codeStart);

  return command.slice(codeStart, codeEnd);
}

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

    const command = readWorkflow('.claude/commands/repo-maintenance.md');
    const script = `
set -euo pipefail
ISSUES=()
${extractRequiredWorkflowScript(command)}
printf '%s\\n' "\${ISSUES[@]}"
`;

    return execFileSync('bash', ['-c', script], { cwd: tempRoot, encoding: 'utf8' });
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

describe('Claude workflow contracts', () => {
  const issueWorkflows = ['.github/workflows/claude.yml', 'templates/workflows/claude.yml'];
  const maintenanceWorkflows = [
    '.github/workflows/scheduled-maintenance.yml',
    'templates/workflows/scheduled-maintenance.yml',
  ];

  test.each(issueWorkflows)('%s creates PRs in a post-Claude Actions step', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);

    expect(workflow).toContain("github.event.sender.type != 'Bot'");
    expect(workflow).toContain('author_association');
    expect(workflow).toContain('OWNER","MEMBER","COLLABORATOR');
    expect(workflow).toContain('name: Create pull request from Claude branch');
    expect(workflow).toContain('GH_TOKEN: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN || github.token }}');
    expect(workflow).toContain('gh pr create');
    expect(workflow).toContain('git ls-remote --exit-code --heads origin "$CLAUDE_BRANCH"');
    expect(workflow).toContain('Claude branch $CLAUDE_BRANCH was not pushed.');
    expect(workflow).not.toContain('Claude branch $CLAUDE_BRANCH was not pushed. Skipping PR creation.');
    expect(workflow).not.toMatch(/Bash\(gh pr create:\*\)/);
    expect(workflow).not.toContain('github_token: ${{ github.token }}');
    expect(workflow).not.toContain('"allowedTools"');
  });

  test.each(maintenanceWorkflows)('%s creates maintenance PRs in a post-Claude Actions step', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);

    expect(workflow).toContain('name: Create maintenance pull request');
    expect(workflow).toContain('CLAUDE_BRANCH: maintenance/${{ github.run_id }}-${{ github.run_attempt }}');
    expect(workflow).toContain('name: Validate maintenance token');
    expect(workflow.indexOf('name: Validate maintenance token')).toBeLessThan(
      workflow.indexOf('name: Checkout repository'),
    );
    expect(workflow).toContain('token: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN }}');
    expect(workflow).toContain('github_token: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN }}');
    expect(workflow).toContain('name: Prepare maintenance branch');
    expect(workflow).toContain('git checkout -b "$CLAUDE_BRANCH"');
    expect(workflow).toContain('Use branch `${{ env.CLAUDE_BRANCH }}`');
    expect(workflow).toContain('GH_TOKEN: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN }}');
    expect(workflow).toContain('if: env.CLAUDE_BRANCH !=');
    expect(workflow).toContain('gh pr create');
    expect(workflow).toContain('git ls-remote --exit-code --heads origin "$CLAUDE_BRANCH"');
    expect(workflow).not.toContain('steps.maintenance.outputs.branch_name');
    expect(workflow).not.toMatch(/Bash\(gh pr create:\*\)/);
    expect(workflow).toContain('Bash(gh api:*)');
    expect(workflow).toContain("/repo-maintenance --mode ${{ inputs.mode || 'full' }} --create-pr");
    expect(workflow).not.toContain('github_token: ${{ github.token }}');
    expect(workflow).not.toContain('"allowedTools"');
  });

  test('Claude Code Review uses the shared CI wait script', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('script/wait-ci-checks.sh "$REPO" "$HEAD_SHA"');
    expect(workflow).not.toContain('QUALITY_GATE_STATUS=');
    expect(workflow).not.toContain('QUALITY_GATE_CONCLUSION=');
  });

  test('Claude Code Review skips Anthropic action when its review gate changes', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('review_gate_changed: ${{ steps.gate-change.outputs.review_gate_changed }}');
    expect(workflow).toContain('gh pr diff "$PR_NUMBER" --repo "$REPO" --name-only');
    expect(workflow).toContain('grep -Fxq ".github/workflows/claude-code-review.yml"');
    expect(workflow).toContain('grep -Fxq "script/wait-ci-checks.sh"');
    expect(workflow).toContain("if: steps.gate-change.outputs.review_gate_changed != 'true'");
    expect(workflow).toContain("needs.check-ci-status.outputs.review_gate_changed != 'true'");
  });

  test('repo-maintenance reports downstream sync when managed files change', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('Downstream sync required');
    expect(command).toContain('Repositories using config-base should run /repo-maintenance or receive a sync PR.');
    expect(command).toContain('"script/wait-ci-checks.sh"');
    expect(command).toContain('git checkout "$CLAUDE_BRANCH" 2>/dev/null || git checkout -b "$CLAUDE_BRANCH"');
  });

  test('repo-maintenance detects required workflow trigger incompatibility', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('Required Workflow Trigger Compatibility Check');
    expect(command).toContain('security-summary.yml');
    expect(command).toContain('security-summary.yaml');
    expect(command).toContain('.github/workflows/*.yaml');
    expect(command).toContain('jobs=[]');
    expect(command).toContain("github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'");
    expect(command).toContain('ON_BLOCK=$(awk');
    expect(command).toContain('/^on:/');
    expect(command).toContain('GENERATE_SUMMARY_JOB=$(awk');
    expect(command).toContain('/^  generate-summary:/');
    expect(command).toContain('/^  [A-Za-z0-9_-]+:/');
    expect(command).toContain("^    if: *github.event_name == 'schedule'");
  });

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
});
