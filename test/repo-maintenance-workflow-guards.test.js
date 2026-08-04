const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const inheritedGitEnvKeys = ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_PREFIX'];

function cleanGitEnv() {
  const env = { ...process.env };
  for (const key of inheritedGitEnvKeys) {
    delete env[key];
  }
  return env;
}

function runCheck(flag, workflows) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'workflow-guards-test-'));

  try {
    for (const [name, content] of Object.entries(workflows)) {
      const target = path.join(tempRoot, '.github', 'workflows', name);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, content);
    }

    const scriptPath = path.join(repoPath, 'script', 'repo-maintenance.sh');
    try {
      const stdout = execFileSync('bash', [scriptPath, flag], {
        cwd: tempRoot,
        env: cleanGitEnv(),
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

// Claude CLI は ANTHROPIC_API_KEY を CLAUDE_CODE_OAUTH_TOKEN より優先する（ADR 0013）。
// 両方を無条件に claude-code-action へ渡すと、失効した API キーが有効な OAuth トークンを
// 握り潰し、401 を約 180 秒リトライしたのち is_error:true / num_turns:1 / total_cost_usd:0
// で無言終了する。keito4/config では 2026-07-29 以降レビューが実行されていなかった。
describe('check_claude_action_credentials', () => {
  const FLAG = '--check-claude-action-credentials';

  function claudeWorkflow(apiKeyLine) {
    return [
      'name: Claude Code Review',
      'jobs:',
      '  review:',
      '    steps:',
      '      - name: Run Claude Code Review',
      '        uses: anthropics/claude-code-action@abc123 # v1',
      '        with:',
      '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
      ...(apiKeyLine ? [`          ${apiKeyLine}`] : []),
      '',
    ].join('\n');
  }

  test('flags an unconditional anthropic_api_key alongside the OAuth token', () => {
    const result = runCheck(FLAG, {
      'claude-code-review.yml': claudeWorkflow('anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}'),
    });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('claude-code-review.yml');
    expect(result.output).toContain('anthropic_api_key');
    expect(result.output).toContain('CLAUDE_CODE_OAUTH_TOKEN');
  });

  test('accepts an anthropic_api_key guarded by the OAuth token being empty', () => {
    const result = runCheck(FLAG, {
      'claude-code-review.yml': claudeWorkflow(
        "anthropic_api_key: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN == '' && secrets.ANTHROPIC_API_KEY || '' }}",
      ),
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('Claude Actions credential precedence ok');
  });

  test('accepts a workflow that passes only the OAuth token', () => {
    const result = runCheck(FLAG, { 'claude.yml': claudeWorkflow(null) });

    expect(result.status).toBe(0);
  });

  test('accepts an API-key-only workflow with no OAuth token to shadow', () => {
    const workflow = [
      'name: Claude',
      'jobs:',
      '  claude:',
      '    steps:',
      '      - uses: anthropics/claude-code-action@abc123 # v1',
      '        with:',
      '          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'claude.yml': workflow });

    expect(result.status).toBe(0);
  });

  test('ignores workflows that do not use claude-code-action', () => {
    const result = runCheck(FLAG, { 'ci.yml': 'name: CI\njobs:\n  build:\n    steps: []\n' });

    expect(result.status).toBe(0);
  });
});

// keito4/intent-gate-android PR #60: release ジョブがバージョンバンプを push した結果、
// その push が起こす新規実行に cancel-in-progress: true で自分自身をキャンセルされ、
// v1.2.49 の GitHub Release アセット添付と Firebase 配信が失われた。
describe('check_self_cancelling_workflows', () => {
  const FLAG = '--check-self-cancelling-workflows';

  function releaseWorkflow(cancelValue, pushStep = true) {
    return [
      'name: CI',
      'on:',
      '  push:',
      '    branches: [main]',
      '  pull_request:',
      'concurrency:',
      '  group: ${{ github.workflow }}-${{ github.ref }}',
      `  cancel-in-progress: ${cancelValue}`,
      'jobs:',
      '  release:',
      '    steps:',
      ...(pushStep ? ['      - run: git push origin HEAD:main'] : ['      - run: echo build']),
      '',
    ].join('\n');
  }

  test('flags a push-triggered workflow that pushes commits while cancelling in progress', () => {
    const result = runCheck(FLAG, { 'ci.yml': releaseWorkflow('true') });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('ci.yml');
    expect(result.output).toContain('cancel-in-progress');
  });

  test('accepts the pull_request-scoped cancel expression', () => {
    const result = runCheck(FLAG, {
      'ci.yml': releaseWorkflow("${{ github.event_name == 'pull_request' }}"),
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('Workflow self-cancellation guards ok');
  });

  test('accepts a push-triggered workflow that does not push commits back', () => {
    const result = runCheck(FLAG, { 'ci.yml': releaseWorkflow('true', false) });

    expect(result.status).toBe(0);
  });

  test('ignores the literal pattern when it only appears inside a comment', () => {
    const workflow = [
      'name: CI',
      'on:',
      '  push:',
      '    branches: [main]',
      'concurrency:',
      '  group: ${{ github.workflow }}-${{ github.ref }}',
      '  # cancel-in-progress: true だと release ジョブが自分自身をキャンセルする',
      "  cancel-in-progress: ${{ github.event_name == 'pull_request' }}",
      'jobs:',
      '  release:',
      '    steps:',
      '      - run: git push origin HEAD:main',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'ci.yml': workflow });

    expect(result.status).toBe(0);
  });

  test('flags a release action that publishes assets from a push-triggered run', () => {
    const workflow = [
      'name: Release',
      'on:',
      '  push:',
      '    tags: ["v*"]',
      'concurrency:',
      '  group: ${{ github.workflow }}-${{ github.ref }}',
      '  cancel-in-progress: true',
      'jobs:',
      '  release:',
      '    steps:',
      '      - uses: softprops/action-gh-release@abc123 # v2',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'release.yml': workflow });

    expect(result.status).not.toBe(0);
  });
});

// keito4/config PR #1066: dependabot-auto ジョブは actions/checkout を実行しないため、
// `gh label create` がリポジトリを git から解決できず
// "failed to run git: fatal: not a git repository" で落ちていた。
// URL 引数を取る `gh pr edit "$PR_URL"` は同じジョブでも通るので気付きにくい。
describe('check_gh_repo_context', () => {
  const FLAG = '--check-gh-repo-context';

  function ghWorkflow({ command, checkout = false, env = [] }) {
    return [
      'name: Dependabot Auto-merge',
      'jobs:',
      '  dependabot-auto:',
      '    steps:',
      ...(checkout ? ['      - uses: actions/checkout@abc123 # v7.0.1'] : []),
      '      - name: Label updates',
      `        run: ${command}`,
      ...(env.length ? ['        env:', ...env.map((line) => `          ${line}`)] : []),
      '',
    ].join('\n');
  }

  test('flags a repo-scoped gh command in a workflow that never checks out', () => {
    const result = runCheck(FLAG, {
      'dependabot-auto-merge.yml': ghWorkflow({ command: 'gh label create "dependabot-minor" --force' }),
    });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('dependabot-auto-merge.yml');
    expect(result.output).toContain('GH_REPO');
  });

  test('accepts the same command once GH_REPO is provided', () => {
    const result = runCheck(FLAG, {
      'dependabot-auto-merge.yml': ghWorkflow({
        command: 'gh label create "dependabot-minor" --force',
        env: ['GH_REPO: ${{ github.repository }}'],
      }),
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('gh repository context ok');
  });

  test('accepts an explicit --repo argument', () => {
    const result = runCheck(FLAG, {
      'health.yml': ghWorkflow({ command: 'gh issue create --repo "$GITHUB_REPOSITORY" --title x' }),
    });

    expect(result.status).toBe(0);
  });

  test('accepts a workflow that checks the repository out', () => {
    const result = runCheck(FLAG, {
      'ci.yml': ghWorkflow({ command: 'gh label create "x" --force', checkout: true }),
    });

    expect(result.status).toBe(0);
  });

  test('ignores gh subcommands that take a pull request URL', () => {
    const result = runCheck(FLAG, {
      'dependabot-auto-merge.yml': ghWorkflow({ command: 'gh pr edit "$PR_URL" --add-label "x"' }),
    });

    expect(result.status).toBe(0);
  });
});
