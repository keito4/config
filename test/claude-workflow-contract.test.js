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
    expect(command).toContain('jobs=[]');
    expect(command).toContain("github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'");
    expect(command).toContain('GENERATE_SUMMARY_JOB=$(awk');
    expect(command).toContain('/^  generate-summary:/');
    expect(command).toContain('/^  [A-Za-z0-9_-]+:/');
    expect(command).toContain("^    if: *github.event_name == 'schedule'");
  });
});
