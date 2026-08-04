const { runCheck } = require('./helpers/workflow-guards');

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

  // 1つでもガード済みの行があるとファイル全体の否定 grep が無効化され、
  // 別ステップの無条件な API キーを見逃す。
  test('flags an unguarded step even when another step is guarded', () => {
    const workflow = [
      'name: Claude',
      'jobs:',
      '  review:',
      '    steps:',
      '      - uses: anthropics/claude-code-action@abc123 # v1',
      '        with:',
      '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
      "          anthropic_api_key: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN == '' && secrets.ANTHROPIC_API_KEY || '' }}",
      '      - uses: anthropics/claude-code-action@abc123 # v1',
      '        with:',
      '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
      '          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'claude.yml': workflow });

    expect(result.status).not.toBe(0);
  });

  // claude-code-action 以外のアクションが anthropic_api_key を取るのは無関係。
  test('does not flag an anthropic_api_key belonging to another action', () => {
    const workflow = [
      'name: Claude',
      'jobs:',
      '  review:',
      '    steps:',
      '      - uses: anthropics/claude-code-action@abc123 # v1',
      '        with:',
      '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
      '      - uses: some-org/other-action@abc123 # v1',
      '        with:',
      '          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'claude.yml': workflow });

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

  // on: [push, ...] / on: push の短縮形もれっきとした push トリガー。
  test.each([['on: [push, pull_request]'], ['on: push']])('recognizes the %s shorthand trigger', (onLine) => {
    const workflow = [
      'name: CI',
      onLine,
      'concurrency:',
      '  group: ${{ github.workflow }}-${{ github.ref }}',
      '  cancel-in-progress: true',
      'jobs:',
      '  release:',
      '    steps:',
      '      - run: git push origin HEAD:main',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'ci.yml': workflow });

    expect(result.status).not.toBe(0);
  });

  // concurrency group が sha / run_id を含むなら、自分が起こす push は別グループに
  // 属するため自分自身をキャンセルできない。
  test.each([['${{ github.sha }}'], ['${{ github.run_id }}']])('accepts a concurrency group keyed by %s', (suffix) => {
    const workflow = [
      'name: Release',
      'on:',
      '  push:',
      '    branches: [main]',
      'concurrency:',
      `  group: \${{ github.workflow }}-${suffix}`,
      '  cancel-in-progress: true',
      'jobs:',
      '  release:',
      '    steps:',
      '      - run: git push origin HEAD:main',
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'release.yml': workflow });

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
