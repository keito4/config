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
  test('TAKT wrapper keeps PR creation outside the command gate', () => {
    const script = readWorkflow('script/run-takt-repo-maintenance.sh');

    expect(script).toContain('MODE_FILE="${TAKT_MAINTENANCE_MODE_FILE:-.context/takt-maintenance-mode}"');
    expect(script).toContain('script/repo-maintenance.sh --mode "$MODE"');
    expect(script).not.toContain('--create-pr');
    expect(script).not.toContain('GH_TOKEN');
    expect(script).not.toContain('CLAUDE_BRANCH');
  });

  test.each(maintenanceWorkflows)('%s runs TAKT maintenance with deterministic PR fallback', (workflowPath) => {
    const workflow = readWorkflow(workflowPath);
    const requiredSnippets = [
      'name: Create maintenance pull request',
      'CLAUDE_BRANCH: maintenance/${{ github.run_id }}-${{ github.run_attempt }}',
      'timeout-minutes: 45',
      'name: Validate maintenance token',
      'name: Validate TAKT authentication',
      'token: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN || secrets.CLAUDE_PAT }}',
      'persist-credentials: false',
      'This managed config-repository workflow depends on .takt/**',
      'uses: ./.github/actions/setup-node-ci',
      'name: Prepare maintenance branch',
      'git checkout -b "$CLAUDE_BRANCH"',
      'git config user.name "github-actions[bot]"',
      'name: Write TAKT maintenance context',
      'printf \'%s\\n\' "$REPO_MAINTENANCE_MODE" > .context/takt-maintenance-mode',
      'name: Run scheduled maintenance with TAKT',
      './node_modules/.bin/takt --pipeline',
      '--skip-git',
      '--quiet',
      '--workflow .takt/workflows/repo-maintenance.yml',
      "REPO_MAINTENANCE_MODE: ${{ inputs.mode || 'full' }}",
      'TAKT_ANTHROPIC_API_KEY: ${{ secrets.TAKT_ANTHROPIC_API_KEY || secrets.ANTHROPIC_API_KEY }}',
      'GH_TOKEN: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN || secrets.CLAUDE_PAT }}',
      'if: env.CLAUDE_BRANCH !=',
      "git add -A -- . ':!.context'",
      'git diff --cached --quiet',
      'git commit -m "chore: scheduled maintenance"',
      'git -c http.https://github.com/.extraheader="AUTHORIZATION: bearer $GH_TOKEN" push -u origin "$CLAUDE_BRANCH"',
      'gh pr create',
      'script/check-trivyignore-review.sh',
    ];
    const forbiddenSnippets = [
      'steps.maintenance.outputs.branch_name',
      'anthropics/claude-code-action',
      'claude_code_oauth_token',
      'Bash(gh pr create:*)',
      'github_token: ${{ github.token }}',
      '"allowedTools"',
      'script/repo-maintenance.sh --mode "$MODE" --create-pr',
      'git ls-remote --exit-code --heads origin "$CLAUDE_BRANCH"',
    ];

    for (const snippet of requiredSnippets) expect(workflow).toContain(snippet);
    expect(workflow.indexOf('name: Validate maintenance token')).toBeLessThan(
      workflow.indexOf('name: Checkout repository'),
    );
    expect(workflow.indexOf('name: Run scheduled maintenance with TAKT')).toBeLessThan(
      workflow.indexOf('name: Create maintenance pull request'),
    );
    const taktStep = workflow.slice(
      workflow.indexOf('name: Run scheduled maintenance with TAKT'),
      workflow.indexOf('name: Create maintenance pull request'),
    );
    expect(taktStep).not.toContain('GH_TOKEN:');
    expect(taktStep).not.toContain('CLAUDE_BRANCH:');
    for (const snippet of forbiddenSnippets) expect(workflow).not.toContain(snippet);
  });

  test('template README documents scheduled maintenance support-file requirements', () => {
    const readme = readWorkflow('templates/README.md');

    expect(readme).toContain('workflow 単体で導入するテンプレートではありません');
    expect(readme).toContain('script/run-takt-repo-maintenance.sh');
    expect(readme).toContain('.github/actions/setup-node-ci');
    expect(readme).toContain('takt');
  });
});
