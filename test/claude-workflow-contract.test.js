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

  test('Claude Code Review skips Anthropic action when authentication is not configured', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('name: Check Claude authentication');
    expect(workflow).toContain('CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}');
    expect(workflow).toContain('ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}');
    expect(workflow).toContain('ANTHROPIC_FEDERATION_RULE_ID: ${{ secrets.ANTHROPIC_FEDERATION_RULE_ID }}');
    expect(workflow).toContain('ANTHROPIC_ORGANIZATION_ID: ${{ secrets.ANTHROPIC_ORGANIZATION_ID }}');
    expect(workflow).toContain('available=false');
    expect(workflow).toContain("if: steps.claude-auth.outputs.available == 'true'");
    expect(workflow).toContain('anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}');
    expect(workflow).toContain('anthropic_federation_rule_id: ${{ secrets.ANTHROPIC_FEDERATION_RULE_ID }}');
    expect(workflow).toContain('anthropic_organization_id: ${{ secrets.ANTHROPIC_ORGANIZATION_ID }}');
  });

  test('repo-maintenance reports downstream sync when managed files change', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('Downstream sync required');
    expect(command).toContain('Repositories using config-base should run /repo-maintenance or receive a sync PR.');
    expect(command).toContain('"script/wait-ci-checks.sh"');
    expect(command).toContain('git checkout "$CLAUDE_BRANCH" 2>/dev/null || git checkout -b "$CLAUDE_BRANCH"');
  });

  test('repo-maintenance guards archived repositories and private dependency review behavior', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('Repository State Guard');
    expect(command).toContain('isArchived,isPrivate');
    expect(command).toContain('REPO_ARCHIVED=$(echo "$REPO_JSON"');
    expect(command).toContain('if [ "$REPO_ARCHIVED" = "true" ]; then');
    expect(command).toContain('CREATE_PR=false');
    expect(command).toContain('Archived repository. Skipping PR creation.');
    expect(command).toContain('REPO_PRIVATE="${REPO_PRIVATE:-false}"');
    expect(command).toContain('Private repo: Dependency Review は optional / skipped を許容');
  });

  test('repo-maintenance validates dependabot and label-sync safety contracts', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('DEPENDABOT_AUTOMERGE_ISSUES');
    expect(command).toContain('TOP_LEVEL_PERMISSIONS');
    expect(command).toContain('DEPENDABOT_JOB_BLOCK');
    expect(command).toContain("if: github.actor == 'dependabot[bot]'");
    expect(command).toContain('workflow-level permissions が read-only ではない');
    expect(command).toContain('workflow-level permissions に write 権限が残っている');
    expect(command).toContain('gh label create "dependabot-minor"');
    expect(command).toContain('gh label create "needs-review"');
    expect(command).toContain('gh label create "breaking-change"');
    expect(command).toContain('LABEL_SYNC_ISSUES');
    expect(command).toContain('checkout 用の contents: read');
    expect(command).toContain('labels.yml: $label が未定義');
  });

  test('repo-maintenance syncs managed dependabot, label-sync, and label templates', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('MANAGED_TEMPLATE_FILES');
    expect(command).toContain(
      'templates/workflows/dependabot-auto-merge.yml:.github/workflows/dependabot-auto-merge.yml',
    );
    expect(command).toContain('templates/workflows/label-sync.yml:.github/workflows/label-sync.yml');
    expect(command).toContain('ensure_label "dependabot-minor"');
    expect(command).toContain('ensure_label "needs-review"');
    expect(command).toContain('ensure_label "breaking-change"');
    expect(command).toContain('差分あり・full modeで更新');
    expect(command).not.toContain('templates/github/labels.yml:.github/labels.yml');
  });

  test('repo-maintenance checks dependency peer compatibility and stores logs under .context', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('Dependency Peer Compatibility Check');
    expect(command).toContain('PEER_ISSUES');
    expect(command).toContain('npm ls --all --json');
    expect(command).toContain('.context/npm-peer-compat.log');
    expect(command).toContain('.context/pnpm-peer-compat.log');
    expect(command).toContain('--frozen-lockfile');
    expect(command).toContain('dependency compatibility issue');
  });

  test('repo-maintenance stores temporary artifacts in .context instead of os temp directories', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('CONTEXT_DIR="${CONTEXT_DIR:-.context}"');
    expect(command).toContain('mktemp "$CONTEXT_DIR/update-agents-md-XXXXX.sh"');
    expect(command).toContain('mktemp -d .context/config-template-XXXXX');
    expect(command).not.toContain('mktemp /tmp/');
    expect(command).not.toContain('mktemp -d)');
  });

  test('update-agents-md includes yaml workflows and keeps check artifacts in .context', () => {
    const script = readWorkflow('script/update-agents-md.sh');

    expect(script).toContain('workflow_files()');
    expect(script).toContain("-name '*.yml' -o -name '*.yaml'");
    expect(script).toContain('CONTEXT_DIR="${CONTEXT_DIR:-.context}"');
    expect(script).toContain('mktemp -d "$CONTEXT_DIR/agents-md-check-XXXXX"');
    expect(script).toContain('prettier --write --ignore-path /dev/null "$target"');
    expect(script).not.toContain('mktemp -d -t agents-md-check');
  });

  test('repo-maintenance scans yml and yaml workflows in cross-workflow checks', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('for wf in .github/workflows/*.yml .github/workflows/*.yaml; do');
    expect(command).toContain('WORKFLOW_FILES=()');
    expect(command).toContain('for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do');
    expect(command).toContain('.github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null');
    expect(command).toContain(
      'for workflow in .github/workflows/ci*.yml .github/workflows/ci*.yaml .github/workflows/test*.yml .github/workflows/test*.yaml; do',
    );
    expect(command).not.toContain('for workflow in .github/workflows/*.yml; do');
    expect(command).not.toContain('for wf in .github/workflows/*.yml; do');
    expect(command).not.toContain('ls .github/workflows/*.yml 2>/dev/null');
    expect(command).not.toContain("grep -rh 'node-version' .github/workflows/*.yml");
  });

  test('dependency health script reports peer dependency issues in its json contract', () => {
    const script = readWorkflow('script/dependency-health-check.sh');

    expect(script).toContain('PEER_ISSUES');
    expect(script).toContain('npm list --all --json');
    expect(script).toContain('select(test("peer|invalid|missing"; "i"))');
    expect(script).toContain('"peer_issues": $PEER_ISSUES');
    expect(script).toContain('"$PEER_ISSUES" -gt 0');
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
    expect(command).toContain('/^"on":/');
    expect(command).toContain('/^\\047on\\047:/');
    expect(command).toContain('events[i] == "pull_request"');
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
