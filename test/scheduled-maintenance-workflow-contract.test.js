const fs = require('fs');
const path = require('path');

const repoPath = path.resolve(__dirname, '..');
const maintenanceWorkflows = [
  '.github/workflows/scheduled-maintenance.yml',
  'templates/workflows/scheduled-maintenance.yml',
];

function readWorkflow(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

describe('Scheduled maintenance workflow contracts', () => {
  test.each(maintenanceWorkflows)('%s runs TAKT maintenance with deterministic PR fallback', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);
    const requiredSnippets = [
      'name: Create maintenance pull request',
      'CLAUDE_BRANCH: maintenance/${{ github.run_id }}-${{ github.run_attempt }}',
      'name: Validate maintenance token',
      'name: Validate TAKT authentication',
      'token: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN || secrets.CLAUDE_PAT }}',
      'uses: ./.github/actions/setup-node-ci',
      'name: Prepare maintenance branch',
      'git checkout -b "$CLAUDE_BRANCH"',
      'git config user.name "github-actions[bot]"',
      'name: Run scheduled maintenance with TAKT',
      './node_modules/.bin/takt --pipeline',
      '--skip-git',
      '--quiet',
      '--workflow .takt/workflows/repo-maintenance.yml',
      "REPO_MAINTENANCE_MODE: ${{ inputs.mode || 'full' }}",
      'TAKT_ANTHROPIC_API_KEY: ${{ secrets.TAKT_ANTHROPIC_API_KEY || secrets.ANTHROPIC_API_KEY }}',
      'GH_TOKEN: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN || secrets.CLAUDE_PAT }}',
      'if: env.CLAUDE_BRANCH !=',
      'gh pr create',
      'git ls-remote --exit-code --heads origin "$CLAUDE_BRANCH"',
      'script/check-trivyignore-review.sh',
    ];
    const forbiddenSnippets = [
      'steps.maintenance.outputs.branch_name',
      'anthropics/claude-code-action',
      'claude_code_oauth_token',
      'Bash(gh pr create:*)',
      'github_token: ${{ github.token }}',
      '"allowedTools"',
    ];

    for (const snippet of requiredSnippets) expect(workflow).toContain(snippet);
    expect(workflow.indexOf('name: Validate maintenance token')).toBeLessThan(
      workflow.indexOf('name: Checkout repository'),
    );
    for (const snippet of forbiddenSnippets) expect(workflow).not.toContain(snippet);
  });
});
