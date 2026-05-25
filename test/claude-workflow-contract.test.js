const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');

function readWorkflow(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('Claude workflow contracts', () => {
  const issueWorkflows = ['.github/workflows/claude.yml', 'templates/workflows/claude.yml'];
  const maintenanceWorkflows = [
    '.github/workflows/scheduled-maintenance.yml',
    'templates/workflows/scheduled-maintenance.yml',
  ];

  test.each(issueWorkflows)('%s creates PRs in a post-Claude Actions step', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);

    expect(workflow).toContain('name: Create pull request from Claude branch');
    expect(workflow).toContain('GH_TOKEN: ${{ steps.claude.outputs.github_token || github.token }}');
    expect(workflow).toContain('gh pr create');
    expect(workflow).not.toMatch(/Bash\(gh pr create:\*\)/);
    expect(workflow).not.toContain('"allowedTools"');
  });

  test.each(maintenanceWorkflows)('%s creates maintenance PRs in a post-Claude Actions step', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);

    expect(workflow).toContain('name: Create maintenance pull request');
    expect(workflow).toContain('GH_TOKEN: ${{ steps.maintenance.outputs.github_token || github.token }}');
    expect(workflow).toContain('gh pr create');
    expect(workflow).not.toMatch(/Bash\(gh pr create:\*\)/);
    expect(workflow).not.toContain('--create-pr');
    expect(workflow).not.toContain('"allowedTools"');
  });

  test('Claude Code Review uses the shared CI wait script', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('script/wait-ci-checks.sh "$REPO" "$HEAD_SHA"');
    expect(workflow).not.toContain('QUALITY_GATE_STATUS=');
    expect(workflow).not.toContain('QUALITY_GATE_CONCLUSION=');
  });

  test('Claude Code Review skips Anthropic action when its workflow changes', () => {
    const workflow = readWorkflow('.github/workflows/claude-code-review.yml');

    expect(workflow).toContain('review_workflow_changed: ${{ steps.workflow-change.outputs.review_workflow_changed }}');
    expect(workflow).toContain('gh pr diff "$PR_NUMBER" --repo "$REPO" --name-only');
    expect(workflow).toContain('grep -Fxq ".github/workflows/claude-code-review.yml"');
    expect(workflow).toContain("needs.check-ci-status.outputs.review_workflow_changed != 'true'");
  });

  test('repo-maintenance reports downstream sync when managed files change', () => {
    const command = readWorkflow('.claude/commands/repo-maintenance.md');

    expect(command).toContain('Downstream sync required');
    expect(command).toContain('Repositories using config-base should run /repo-maintenance or receive a sync PR.');
  });
});
