const fs = require('fs');
const path = require('path');
const { execFileSync, spawnSync } = require('child_process');
const yaml = require('js-yaml');

const repoPath = path.resolve(__dirname, '..');
const workflows = ['.github/workflows/claude.yml', 'templates/workflows/claude.yml'];
// Git hooks export repository paths; never let fixture commands target that repo.
const gitEnv = { ...process.env };
for (const key of execFileSync('git', ['rev-parse', '--local-env-vars'], { encoding: 'utf8' }).trim().split('\n')) {
  delete gitEnv[key];
}

describe.each(workflows)('%s verifies publication before succeeding', (workflowPath) => {
  let dir;
  let repo;
  let log;
  let env;
  const git = (...args) => {
    const result = spawnSync('git', args, { cwd: repo, env: gitEnv, encoding: 'utf8' });
    if (result.status !== 0) throw new Error(result.stderr);
    return result.stdout.trim();
  };

  beforeEach(() => {
    const context = path.join(repoPath, '.context');
    fs.mkdirSync(context, { recursive: true });
    dir = fs.mkdtempSync(path.join(context, 'claude-publish-'));
    repo = path.join(dir, 'repo');
    const remote = path.join(dir, 'remote.git');
    const bin = path.join(dir, 'bin');
    log = path.join(dir, 'gh-calls');
    fs.mkdirSync(repo);
    fs.mkdirSync(bin);
    git('init', '--bare', remote);
    git('init', '-b', 'main');
    git('config', 'user.name', 'Test');
    git('config', 'user.email', 'test@example.invalid');
    fs.writeFileSync(path.join(repo, 'tracked'), 'base\n');
    git('add', 'tracked');
    git('commit', '-m', 'base');
    git('remote', 'add', 'origin', remote);
    git('push', 'origin', 'main');
    git('checkout', '-b', 'claude/12');
    fs.writeFileSync(path.join(bin, 'gh'), '#!/bin/bash\nprintf "%s\\n" "$@" >> "$CALL_LOG"\n', { mode: 0o755 });
    env = {
      ...gitEnv,
      PATH: `${bin}:${process.env.PATH}`,
      CALL_LOG: log,
      CLAUDE_BRANCH: 'claude/12',
      CLAUDE_TASK_COMPLETE: 'true',
      DEFAULT_BRANCH: 'main',
      INITIAL_CHECKOUT_SHA: git('rev-parse', 'HEAD'),
      ISSUE_NUMBER: '12',
      ISSUE_TITLE: 'Requested change',
      PR_ASSIGNEE: 'reviewer',
    };
  });

  afterEach(() => fs.rmSync(dir, { recursive: true, force: true }));

  function step() {
    const workflow = yaml.load(fs.readFileSync(path.join(repoPath, workflowPath), 'utf8'));
    return workflow.jobs.claude.steps.find((entry) => entry.name === 'Create pull request from Claude branch');
  }

  function run() {
    return spawnSync('bash', ['--noprofile', '--norc', '-eo', 'pipefail', '-c', step().run], {
      cwd: repo,
      env,
      encoding: 'utf8',
    });
  }

  function change(scenario) {
    if (scenario === 'incomplete') env.CLAUDE_TASK_COMPLETE = 'false';
    if (['committed', 'modified', 'staged'].includes(scenario)) {
      fs.writeFileSync(path.join(repo, 'tracked'), 'changed\n');
    }
    if (['committed', 'staged'].includes(scenario)) git('add', 'tracked');
    if (scenario === 'committed') git('commit', '-m', 'undelivered');
    if (scenario === 'untracked') fs.writeFileSync(path.join(repo, 'new-file'), 'undelivered\n');
    if (scenario === 'remote-error') git('remote', 'set-url', 'origin', path.join(dir, 'missing.git'));
    if (scenario === 'missing-ref') {
      git('checkout', 'main');
      git('branch', '-D', 'claude/12');
    }
    if (scenario === 'missing-base') git('branch', '-D', 'main');
    if (scenario === 'missing-initial') env.INITIAL_CHECKOUT_SHA = '';
    if (scenario === 'wrong-initial') env.INITIAL_CHECKOUT_SHA = '0'.repeat(40);
    if (scenario === 'advanced-local-base') {
      git('checkout', 'main');
      fs.writeFileSync(path.join(repo, 'tracked'), 'undelivered default-branch change\n');
      git('add', 'tracked');
      git('commit', '-m', 'undelivered on main');
      git('checkout', 'claude/12');
      git('merge', '--ff-only', 'main');
    }
    if (scenario === 'other-head') {
      git('checkout', '-b', 'other');
      git('commit', '--allow-empty', '-m', 'different head');
    }
  }

  test.each([
    'no-code',
    'incomplete',
    'committed',
    'modified',
    'staged',
    'untracked',
    'remote-error',
    'missing-ref',
    'missing-base',
    'missing-initial',
    'wrong-initial',
    'advanced-local-base',
    'other-head',
  ])('handles absent remote branch: %s', (scenario) => {
    change(scenario);

    const result = run();
    expect({ success: result.status === 0, calledGh: fs.existsSync(log) }).toEqual({
      success: scenario === 'no-code',
      calledGh: false,
    });
  });

  test.each(['committed', 'modified', 'staged', 'untracked', 'other-head', 'missing-ref', 'remote-error'])(
    'rejects undelivered work after an earlier push: %s',
    (scenario) => {
      git('push', 'origin', 'claude/12');
      change(scenario);
      expect(run().status).not.toBe(0);
      expect(fs.existsSync(log)).toBe(false);
    },
  );

  test.each(['true', 'false'])('fails closed without a branch output even with task_complete=%s', (complete) => {
    env.CLAUDE_BRANCH = '';
    env.CLAUDE_TASK_COMPLETE = complete;
    expect(run().status).not.toBe(0);
    expect(fs.existsSync(log)).toBe(false);
  });

  test('runs the guard for empty-branch Issue results while preserving auth, PR and cancellation skips', () => {
    const eligible = new Function(
      'steps',
      'github',
      'cancelled',
      `return (${step().if.replaceAll('steps.claude-auth', 'steps["claude-auth"]')});`,
    );
    const steps = {
      claude: { outcome: 'success', outputs: { branch_name: '' } },
      'claude-auth': { outputs: { available: 'true' } },
    };
    const github = { event_name: 'issues', event: { issue: {} } };
    expect(eligible(steps, github, () => false)).toBe(true);
    steps.claude.outcome = 'failure';
    expect(eligible(steps, github, () => false)).toBe(true);
    steps.claude.outcome = 'skipped';
    expect(eligible(steps, github, () => false)).toBe(false);
    steps.claude.outcome = 'success';
    steps['claude-auth'].outputs.available = 'false';
    expect(eligible(steps, github, () => false)).toBe(false);
    steps['claude-auth'].outputs.available = 'true';
    expect(eligible(steps, github, () => true)).toBe(false);
    github.event_name = 'issue_comment';
    github.event.issue.pull_request = { url: 'https://github.com/owner/repo/pull/12' };
    expect(eligible(steps, github, () => false)).toBe(false);
  });

  test('captures the actual checkout before Claude and fails if capture fails', () => {
    const steps = yaml.load(fs.readFileSync(path.join(repoPath, workflowPath), 'utf8')).jobs.claude.steps;
    const capture = steps.find((entry) => entry.id === 'checkout-base');
    expect(capture).toBeDefined();
    expect(steps.indexOf(capture)).toBeGreaterThan(steps.findIndex((entry) => entry.name === 'Checkout repository'));
    expect(steps.indexOf(capture)).toBeLessThan(steps.findIndex((entry) => entry.id === 'claude'));
    expect(capture.if).toBe("steps.pr_draft.outputs.is_draft != 'true'");
    expect(step().env.INITIAL_CHECKOUT_SHA).toBe('${{ steps.checkout-base.outputs.sha }}');
    const output = path.join(dir, 'checkout-output');
    const executeCapture = (extra = {}) =>
      spawnSync('bash', ['-eo', 'pipefail', '-c', capture.run], {
        cwd: repo,
        env: { ...gitEnv, GITHUB_OUTPUT: output, ...extra },
        encoding: 'utf8',
      });
    expect(executeCapture().status).toBe(0);
    expect(fs.readFileSync(output, 'utf8')).toBe(`sha=${env.INITIAL_CHECKOUT_SHA}\n`);
    fs.rmSync(output);
    expect(executeCapture({ GIT_DIR: path.join(dir, 'missing-git') }).status).not.toBe(0);
    expect(fs.existsSync(output)).toBe(false);
  });

  test.each(['true', 'false'])('preserves PR policy for a published branch with task_complete=%s', (complete) => {
    fs.writeFileSync(path.join(repo, 'tracked'), 'published\n');
    git('add', 'tracked');
    git('commit', '-m', 'delivered');
    git('push', 'origin', 'claude/12');
    env.CLAUDE_TASK_COMPLETE = complete;

    expect(run().status).toBe(0);
    const args = fs.readFileSync(log, 'utf8');
    expect(args).toContain('create\n--head\nclaude/12\n--base\nmain');
    expect(args).toContain('--assignee\nreviewer');
    expect(args).toContain(complete === 'true' ? 'Closes #12' : 'Refs #12');
    expect(args.includes('--draft')).toBe(complete !== 'true');
  });
});
