const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

function runActionsPrSettingsScript(workflowSettings) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'actions-pr-settings-test-'));

  try {
    const binDir = path.join(tempRoot, 'bin');
    fs.mkdirSync(binDir, { recursive: true });
    const ghPath = path.join(binDir, 'gh');
    fs.writeFileSync(ghPath, buildGhStub(workflowSettings));
    fs.chmodSync(ghPath, 0o755);

    const scriptPath = path.join(repoPath, 'script', 'repo-maintenance.sh');
    try {
      const stdout = execFileSync('bash', [scriptPath, '--check-actions-pr-settings'], {
        cwd: tempRoot,
        env: { ...process.env, PATH: `${binDir}:${process.env.PATH}` },
        encoding: 'utf8',
      });
      return { status: 0, output: stdout };
    } catch (error) {
      return { status: error.status, output: `${error.stdout || ''}${error.stderr || ''}` };
    }
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

function buildGhStub(workflowSettings) {
  return [
    '#!/bin/sh',
    'if [ "$1" = "repo" ] && [ "$2" = "view" ]; then',
    '  echo "owner/repo"',
    '  exit 0',
    'fi',
    'if [ "$1" = "api" ]; then',
    `  cat <<'JSON'\n${JSON.stringify(workflowSettings)}\nJSON`,
    '  exit 0',
    'fi',
    'exit 1',
    '',
  ].join('\n');
}

describe('repo-maintenance GitHub Actions PR creation settings', () => {
  test('documents and checks repository workflow permissions needed for automated PR creation', () => {
    const command = readRepoFile('.claude/commands/repo-maintenance.md');
    const script = readRepoFile('script/repo-maintenance.sh');

    expect(command).toContain('script/repo-maintenance.sh --check-actions-pr-settings');
    expect(command).toContain('default_workflow_permissions=write');
    expect(command).toContain('can_approve_pull_request_reviews=true');
    expect(script).toContain('check_actions_pr_creation_settings');
    expect(script).toContain('repos/$repo/actions/permissions/workflow');
    expect(script).toContain('https://github.com/$repo/settings/actions');
  });

  test('succeeds when Actions can create pull requests', () => {
    const result = runActionsPrSettingsScript({
      default_workflow_permissions: 'write',
      can_approve_pull_request_reviews: true,
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('GitHub Actions PR creation settings ok');
  });

  test('warns with settings URL when Actions cannot create pull requests', () => {
    const result = runActionsPrSettingsScript({
      default_workflow_permissions: 'read',
      can_approve_pull_request_reviews: false,
    });

    expect(result.status).toBe(1);
    expect(result.output).toContain("default workflow permissions are 'read'");
    expect(result.output).toContain('GitHub Actions PR creation is disabled');
    expect(result.output).toContain('https://github.com/owner/repo/settings/actions');
  });
});
