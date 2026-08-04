const { runCheck } = require('./helpers/workflow-guards');

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

  // ジョブAの checkout はジョブBの gh を設定しない。
  test('flags a checkout-less job even when a sibling job checks out', () => {
    const workflow = [
      'name: CI',
      'jobs:',
      '  build:',
      '    steps:',
      '      - uses: actions/checkout@abc123 # v7.0.1',
      '  label:',
      '    steps:',
      '      - name: Label updates',
      '        run: gh label create "dependabot-minor" --force',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'ci.yml': workflow });

    expect(result.status).not.toBe(0);
  });

  // 別コマンドに付いた --repo は gh label create を設定しない。
  test('flags a command without --repo even when a sibling command has one', () => {
    const workflow = [
      'name: CI',
      'jobs:',
      '  label:',
      '    steps:',
      '      - name: Label updates',
      '        run: |',
      '          gh issue list --repo "$GITHUB_REPOSITORY"',
      '          gh label create "dependabot-minor" --force',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'ci.yml': workflow });

    expect(result.status).not.toBe(0);
  });

  // gh は -R / --repo= も受け付ける。検査が CI をブロックする以上、
  // 正しい書き方を落とすと正当な PR が止まる。
  test.each([['-R "$GITHUB_REPOSITORY"'], ['--repo="$GITHUB_REPOSITORY"']])(
    'accepts the %s form of the repository flag',
    (flag) => {
      const result = runCheck(FLAG, {
        'health.yml': ghWorkflow({ command: `gh issue create ${flag} --title x` }),
      });

      expect(result.status).toBe(0);
    },
  );

  test('ignores gh subcommands that take a pull request URL', () => {
    const result = runCheck(FLAG, {
      'dependabot-auto-merge.yml': ghWorkflow({ command: 'gh pr edit "$PR_URL" --add-label "x"' }),
    });

    expect(result.status).toBe(0);
  });
});

// config は templates/workflows/ を下流リポジトリへ配布する。ここを走査しないと、
// 配布物に入った不具合を config 側の検査が検出できない（実際 claude-health-check.yml の
// gh バグは .github/workflows/ しか見ていなかったため検査をすり抜けていた）。
describe('workflow guards cover distributed templates', () => {
  test('--check-gh-repo-context flags a template that never checks out', () => {
    const workflow = [
      'name: Claude Code Health Check',
      'jobs:',
      '  health-check:',
      '    steps:',
      '      - name: Create issue on failure',
      '        env:',
      '          GH_TOKEN: ${{ github.token }}',
      '        run: gh issue create --title x',
      '',
    ].join('\n');

    const result = runCheck('--check-gh-repo-context', {
      'templates/workflows/claude-health-check.yml': workflow,
    });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('claude-health-check.yml');
  });

  test('--check-claude-action-credentials flags a template that shadows the OAuth token', () => {
    const workflow = [
      'name: Claude',
      'jobs:',
      '  claude:',
      '    steps:',
      '      - uses: anthropics/claude-code-action@abc123 # v1',
      '        with:',
      '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
      '          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}',
      '',
    ].join('\n');

    const result = runCheck('--check-claude-action-credentials', {
      'templates/workflows/claude.yml': workflow,
    });

    expect(result.status).not.toBe(0);
  });

  test('--check-self-cancelling-workflows flags a template that cancels its own push', () => {
    const workflow = [
      'name: Release',
      'on: [push]',
      'concurrency:',
      '  group: ${{ github.workflow }}',
      '  cancel-in-progress: true',
      'jobs:',
      '  release:',
      '    steps:',
      '      - run: git push origin HEAD:main',
      '',
    ].join('\n');

    const result = runCheck('--check-self-cancelling-workflows', {
      'templates/workflows/release.yml': workflow,
    });

    expect(result.status).not.toBe(0);
  });

  test('also covers reusable workflow templates under .github/workflows/templates', () => {
    const workflow = [
      'name: Reusable',
      'jobs:',
      '  label:',
      '    steps:',
      '      - run: gh label create "x" --force',
      '',
    ].join('\n');

    const result = runCheck('--check-gh-repo-context', {
      '.github/workflows/templates/reusable.yml': workflow,
    });

    expect(result.status).not.toBe(0);
  });
});
