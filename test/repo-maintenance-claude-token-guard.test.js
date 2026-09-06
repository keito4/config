const { runCheck } = require('./helpers/workflow-guards');

// トークン未設定でも claude-code-action は起動し、認証に失敗して赤で終わる。
// 呼び出し側が continue-on-error: true を付けているため、ワークフローは緑のまま
// ジョブだけが黙って赤になる。keito4/calendar_alerm#88 / keito4/effectuation#5 で
// 実際にこれが起き、レビューが止まっていることに気付けなかった。
// トークンが無いときは skip させ、失敗と欠落を区別できるようにする。
describe('check_claude_token_guard', () => {
  const FLAG = '--check-claude-token-guard';

  const AUTH_STEP = [
    '      - name: Check Claude authentication',
    '        id: claude-auth',
    '        env:',
    '          CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
    '        run: |',
    '          if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then',
    '            echo "available=true" >> "$GITHUB_OUTPUT"',
    '          else',
    '            echo "available=false" >> "$GITHUB_OUTPUT"',
    '          fi',
  ];

  function workflow(lines) {
    return ['name: Claude', 'jobs:', '  claude:', '    steps:', ...lines, ''].join('\n');
  }

  const RUN_STEP = [
    '      - name: Run Claude Code',
    '        id: claude',
    '        uses: anthropics/claude-code-action@abc123 # v1',
    '        with:',
    '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
  ];

  test('flags a claude-code-action step with no auth guard', () => {
    const result = runCheck(FLAG, { 'claude.yml': workflow([...AUTH_STEP.slice(0, 0), ...RUN_STEP]) });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('claude.yml');
    expect(result.output).toContain('claude-auth');
  });

  test('accepts a step gated on the auth check output', () => {
    const result = runCheck(FLAG, {
      'claude.yml': workflow([
        ...AUTH_STEP,
        ...RUN_STEP.slice(0, 2),
        "        if: steps.claude-auth.outputs.available == 'true'",
        ...RUN_STEP.slice(2),
      ]),
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('Claude token guard ok');
  });

  // 下書き判定などの無関係な条件は認証ガードではない。ここを緩めると、
  // if: が付いてさえいれば通ってしまい検査が意味を失う。
  test('flags a step gated on an unrelated step output', () => {
    const result = runCheck(FLAG, {
      'claude.yml': workflow([
        ...RUN_STEP.slice(0, 2),
        "        if: steps.pr_draft.outputs.is_draft != 'true'",
        ...RUN_STEP.slice(2),
      ]),
    });

    expect(result.status).not.toBe(0);
  });

  // 認証ガードと他の条件を && で連結した形は実際に使われている。
  test('accepts an auth guard combined with another condition', () => {
    const result = runCheck(FLAG, {
      'claude.yml': workflow([
        ...AUTH_STEP,
        ...RUN_STEP.slice(0, 2),
        "        if: steps.pr_draft.outputs.is_draft != 'true' && steps.claude-auth.outputs.available == 'true'",
        ...RUN_STEP.slice(2),
      ]),
    });

    expect(result.status).toBe(0);
  });

  // レビュー側は has_review_token という別名を使っている。
  test('accepts a token-named guard output', () => {
    const result = runCheck(FLAG, {
      'claude-code-review.yml': workflow([
        ...RUN_STEP.slice(0, 2),
        "        if: steps.check-token.outputs.has_review_token == 'true'",
        ...RUN_STEP.slice(2),
      ]),
    });

    expect(result.status).toBe(0);
  });

  // 前段で認証を検証して落とすワークフローは、黙って赤くなる問題を持たない。
  // config 自身の scheduled-maintenance.yml がこの形。
  test('accepts a workflow that validates authentication up front', () => {
    const result = runCheck(FLAG, {
      'scheduled-maintenance.yml': workflow([
        '      - name: Validate TAKT authentication',
        '        run: script/validate-takt-auth.sh',
        ...RUN_STEP,
      ]),
    });

    expect(result.status).toBe(0);
  });

  // keito4/effectuation はジョブ全体を needs の出力で塞いでいる。ステップの if: だけを
  // 見ると、正しく直したリポジトリを違反として報告してしまう。
  test('accepts a job gated on a needs output token check', () => {
    const workflow = [
      'name: Claude Code Review',
      'jobs:',
      '  check-ci-status:',
      '    runs-on: ubuntu-latest',
      '    outputs:',
      '      has_review_token: ${{ steps.review-token.outputs.has_review_token }}',
      '    steps:',
      '      - id: review-token',
      '        run: echo "has_review_token=true" >> "$GITHUB_OUTPUT"',
      '  claude-review:',
      "    if: needs.check-ci-status.outputs.has_review_token == 'true'",
      '    needs: [check-ci-status]',
      '    steps:',
      ...RUN_STEP,
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'claude-code-review.yml': workflow });

    expect(result.status).toBe(0);
  });

  // ジョブのガードは同じジョブにしか効かない。別ジョブの未ガードを覆い隠さないこと。
  test('flags an unguarded job even when another job is gated', () => {
    const workflow = [
      'name: Claude',
      'jobs:',
      '  gated:',
      "    if: needs.check.outputs.has_review_token == 'true'",
      '    steps:',
      ...RUN_STEP,
      '  ungated:',
      '    steps:',
      ...RUN_STEP,
      '',
    ].join('\n');

    const result = runCheck(FLAG, { 'claude.yml': workflow });

    expect(result.status).not.toBe(0);
  });

  test('ignores workflows that do not use claude-code-action', () => {
    const result = runCheck(FLAG, { 'ci.yml': 'name: CI\njobs:\n  build:\n    steps: []\n' });

    expect(result.status).toBe(0);
  });

  // ガード済みのステップが1つあっても、別ステップの未ガードは見逃さない。
  test('flags an unguarded step even when another step is guarded', () => {
    const result = runCheck(FLAG, {
      'claude.yml': workflow([
        ...AUTH_STEP,
        ...RUN_STEP.slice(0, 2),
        "        if: steps.claude-auth.outputs.available == 'true'",
        ...RUN_STEP.slice(2),
        '      - name: Run Claude Code again',
        '        uses: anthropics/claude-code-action@abc123 # v1',
        '        with:',
        '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
      ]),
    });

    expect(result.status).not.toBe(0);
  });
});
