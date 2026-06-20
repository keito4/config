const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');

function readRepoFile(relativePath) {
  return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
}

function runRepoMaintenanceScript(args, options = {}) {
  const { files = {}, ghStub = buildGhStub(options), env = {} } = options;
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'actions-pr-settings-test-'));

  try {
    for (const [relativePath, content] of Object.entries(files)) {
      const target = path.join(tempRoot, relativePath);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, content);
    }

    const binDir = path.join(tempRoot, 'bin');
    fs.mkdirSync(binDir, { recursive: true });
    const ghPath = path.join(binDir, 'gh');
    fs.writeFileSync(ghPath, ghStub);
    fs.chmodSync(ghPath, 0o755);

    const scriptPath = path.join(repoPath, 'script', 'repo-maintenance.sh');
    try {
      const stdout = execFileSync('bash', [scriptPath, ...args], {
        cwd: tempRoot,
        env: { ...process.env, ...env, PATH: `${binDir}:${process.env.PATH}` },
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

function runActionsPrSettingsScript(workflowSettings) {
  return runRepoMaintenanceScript(['--check-actions-pr-settings'], { workflowSettings });
}

function buildGhStub({ workflowSettings, secrets = [], prLog } = {}) {
  const workflowResponse = JSON.stringify(workflowSettings || {});
  const secretOutput = secrets.join('\n');
  return [
    '#!/bin/sh',
    'if [ "$1" = "repo" ] && [ "$2" = "view" ]; then',
    '  case "$*" in',
    '    *isArchived*) echo \'{"nameWithOwner":"owner/repo","isArchived":false,"isPrivate":false}\' ;;',
    '    *) echo "owner/repo" ;;',
    '  esac',
    '  exit 0',
    'fi',
    'if [ "$1" = "secret" ] && [ "$2" = "list" ]; then',
    `  cat <<'SECRETS'\n${secretOutput}\nSECRETS`,
    '  exit 0',
    'fi',
    'if [ "$1" = "pr" ] && [ "$2" = "create" ]; then',
    prLog ? `  printf '%s\\n' "$*" > '${prLog}'` : '  echo "$*"',
    '  echo "owner/repo"',
    '  exit 0',
    'fi',
    'if [ "$1" = "api" ]; then',
    `  cat <<'JSON'\n${workflowResponse}\nJSON`,
    '  exit 0',
    'fi',
    'exit 1',
    '',
  ].join('\n');
}

function scheduledMaintenanceWorkflow() {
  return [
    'name: Scheduled Maintenance',
    'jobs:',
    '  maintenance:',
    '    steps:',
    '      - name: Use token',
    '        env:',
    '          CLAUDE_PR_GITHUB_TOKEN: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN }}',
    '      - name: Post failure issue',
    '        env:',
    '          GH_REPO: ${{ github.repository }}',
    '        run: gh issue create --title failed --body failed',
    '',
  ].join('\n');
}

function runCreatePrWithClaudeBranch() {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'create-pr-branch-test-'));

  try {
    const remote = path.join(tempRoot, 'remote.git');
    const worktree = path.join(tempRoot, 'worktree');
    const binDir = path.join(tempRoot, 'bin');
    const prLog = path.join(tempRoot, 'pr.log');
    fs.mkdirSync(binDir, { recursive: true });
    fs.mkdirSync(worktree, { recursive: true });

    fs.writeFileSync(path.join(binDir, 'gh'), buildGhStub({ prLog }));
    fs.chmodSync(path.join(binDir, 'gh'), 0o755);

    execFileSync('git', ['init', '--bare', remote], { stdio: 'ignore' });
    execFileSync('git', ['init'], { cwd: worktree, stdio: 'ignore' });
    execFileSync('git', ['config', 'user.name', 'Test User'], { cwd: worktree });
    execFileSync('git', ['config', 'user.email', 'test@example.com'], { cwd: worktree });
    fs.writeFileSync(path.join(worktree, 'README.md'), 'initial\n');
    execFileSync('git', ['add', 'README.md'], { cwd: worktree });
    execFileSync('git', ['commit', '-m', 'chore: initial'], { cwd: worktree, stdio: 'ignore' });
    execFileSync('git', ['branch', '-M', 'main'], { cwd: worktree });
    execFileSync('git', ['remote', 'add', 'origin', remote], { cwd: worktree });
    execFileSync('git', ['push', '-u', 'origin', 'main'], { cwd: worktree, stdio: 'ignore' });
    fs.writeFileSync(path.join(worktree, 'README.md'), 'updated\n');

    const scriptPath = path.join(repoPath, 'script', 'repo-maintenance.sh');
    execFileSync(
      'bash',
      [
        scriptPath,
        '--create-pr',
        '--skip',
        'setup',
        '--skip',
        'dependencies',
        '--skip',
        'quality',
        '--skip',
        'discovery',
      ],
      {
        cwd: worktree,
        env: { ...process.env, CLAUDE_BRANCH: 'maintenance/test-branch', PATH: `${binDir}:${process.env.PATH}` },
        encoding: 'utf8',
      },
    );

    return {
      branch: execFileSync('git', ['branch', '--show-current'], { cwd: worktree, encoding: 'utf8' }).trim(),
      prArgs: fs.readFileSync(prLog, 'utf8'),
    };
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

describe('repo-maintenance GitHub Actions PR creation settings', () => {
  test('documents and checks repository workflow permissions needed for automated PR creation', () => {
    const command = readRepoFile('.claude/commands/repo-maintenance.md');
    const script = readRepoFile('script/repo-maintenance.sh');
    const extraChecks = readRepoFile('script/lib/repo_maintenance_checks.sh');

    expect(command).toContain('script/repo-maintenance.sh --check-actions-pr-settings');
    expect(command).toContain('script/repo-maintenance.sh --check-scheduled-maintenance');
    expect(command).toContain('script/repo-maintenance.sh --check-artifact-retention');
    expect(command).toContain('default_workflow_permissions=write');
    expect(command).toContain('can_approve_pull_request_reviews=true');
    expect(script).toContain('check_actions_pr_creation_settings');
    expect(script).toContain('check_scheduled_maintenance_configuration');
    expect(script).toContain('check_artifact_retention');
    expect(script).toContain('repos/$repo/actions/permissions/workflow');
    expect(script).toContain('https://github.com/$repo/settings/actions');
    expect(extraChecks).toContain('CLAUDE_PR_GITHUB_TOKEN');
    expect(extraChecks).toContain('retention-days is %s (expected <= 30)');
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

  test('fails before creating a PR when Actions PR settings are invalid', () => {
    const result = runRepoMaintenanceScript(
      ['--create-pr', '--skip', 'dependencies', '--skip', 'quality', '--skip', 'discovery'],
      {
        workflowSettings: {
          default_workflow_permissions: 'read',
          can_approve_pull_request_reviews: false,
        },
      },
    );

    expect(result.status).toBe(1);
    expect(result.output).toContain('https://github.com/owner/repo/settings/actions');
  });

  test('uses CLAUDE_BRANCH for repo-maintenance PR creation', () => {
    const result = runCreatePrWithClaudeBranch();

    expect(result.branch).toBe('maintenance/test-branch');
    expect(result.prArgs).toContain('--head maintenance/test-branch');
  });

  test('checks scheduled maintenance secret and failure issue routing', () => {
    const result = runRepoMaintenanceScript(['--check-scheduled-maintenance'], {
      files: { '.github/workflows/scheduled-maintenance.yml': scheduledMaintenanceWorkflow() },
      secrets: [],
    });

    expect(result.status).toBe(1);
    expect(result.output).toContain('requires CLAUDE_PR_GITHUB_TOKEN or CLAUDE_PAT secret');
    expect(result.output).toContain('https://github.com/owner/repo/settings/secrets/actions');
  });

  test('accepts scheduled maintenance when required secret is present', () => {
    const result = runRepoMaintenanceScript(['--check-scheduled-maintenance'], {
      files: {
        '.github/workflows/scheduled-maintenance.yml': readRepoFile('templates/workflows/scheduled-maintenance.yml'),
      },
      secrets: ['CLAUDE_PAT'],
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('Scheduled Maintenance configuration ok');
  });

  test('checks artifact retention days', () => {
    const result = runRepoMaintenanceScript(['--check-artifact-retention'], {
      files: {
        '.github/workflows/artifact.yml': [
          'name: Artifact',
          'jobs:',
          '  artifact:',
          '    steps:',
          '      - uses: actions/upload-artifact@v4',
          '        with:',
          '          retention-days: 90',
          '',
        ].join('\n'),
      },
    });

    expect(result.status).toBe(1);
    expect(result.output).toContain('artifact retention-days is 90');
  });
});
