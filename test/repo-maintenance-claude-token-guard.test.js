const { runCheck } = require('./helpers/workflow-guards');

// トークンが無くても claude-code-action は起動し、認証に失敗して赤で終わる。
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

  const RUN_STEP = [
    '      - name: Run Claude Code',
    '        id: claude',
    '        uses: anthropics/claude-code-action@abc123 # v1',
    '        with:',
    '          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}',
  ];

  /** ジョブ1つ・ステップ列 lines のワークフローを組み立てる。 */
  function workflow(lines) {
    return ['name: Claude', 'jobs:', '  claude:', '    steps:', ...lines, ''].join('\n');
  }

  /** RUN_STEP に step-level の if: を差し込む。 */
  function guardedRun(ifLine) {
    return [...RUN_STEP.slice(0, 2), `        if: ${ifLine}`, ...RUN_STEP.slice(2)];
  }

  const GUARD = "steps.claude-auth.outputs.available == 'true'";

  const ACCEPTED = [
    ['a step gated on the auth check output', workflow([...AUTH_STEP, ...guardedRun(GUARD)])],
    [
      'an auth guard combined with another condition',
      workflow([...AUTH_STEP, ...guardedRun(`steps.pr_draft.outputs.is_draft != 'true' && ${GUARD}`)]),
    ],
    // レビュー側は has_review_token という別名を使っている。
    ['a token-named guard output', workflow(guardedRun("steps.check-token.outputs.has_review_token == 'true'"))],
    // config 自身の scheduled-maintenance.yml の形。
    [
      'a job that validates authentication before the action',
      workflow(['      - run: script/validate-takt-auth.sh', ...RUN_STEP]),
    ],
    // keito4/effectuation はジョブ全体を needs の出力で塞いでいる。ステップの if: だけを
    // 見ると、正しく直したリポジトリを違反として報告してしまう。
    [
      'a job gated on a needs output token check',
      [
        'name: Claude Code Review',
        'jobs:',
        '  claude-review:',
        "    if: needs.check-ci-status.outputs.has_review_token == 'true'",
        '    needs: [check-ci-status]',
        '    steps:',
        ...RUN_STEP,
        '',
      ].join('\n'),
    ],
    ['a workflow with no claude-code-action', 'name: CI\njobs:\n  build:\n    steps: []\n'],
  ];

  const REJECTED = [
    ['no guard at all', workflow(RUN_STEP)],
    // 下書き判定などの無関係な条件は認証ガードではない。ここを緩めると、
    // if: が付いてさえいれば通ってしまい検査が意味を失う。
    ['an unrelated step output', workflow(guardedRun("steps.pr_draft.outputs.is_draft != 'true'"))],
    // 否定形と || による迂回は、トークンが無いときに動いてしまう。
    [
      'a negated availability check',
      workflow([...AUTH_STEP, ...guardedRun("steps.claude-auth.outputs.available != 'true'")]),
    ],
    [
      'an inverted availability check',
      workflow([...AUTH_STEP, ...guardedRun("steps.claude-auth.outputs.available == 'false'")]),
    ],
    ['an always() bypass', workflow([...AUTH_STEP, ...guardedRun(`${GUARD} || always()`)])],
    // ガード済みの 1 ステップ／ジョブが、同じファイルの未ガードを覆い隠さないこと。
    ['a second unguarded step', workflow([...AUTH_STEP, ...guardedRun(GUARD), ...RUN_STEP])],
    [
      'a second unguarded job',
      [
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
      ].join('\n'),
    ],
    // preflight は「同じジョブで」「action より前に」実行されて初めて意味を持つ。
    ['a preflight named only in a comment', workflow(['      # script/validate-takt-auth.sh に寄せたい', ...RUN_STEP])],
    [
      'a preflight in a different job',
      [
        'name: Scheduled Maintenance',
        'jobs:',
        '  preflight:',
        '    steps:',
        '      - run: script/validate-takt-auth.sh',
        '  maintenance:',
        '    steps:',
        ...RUN_STEP,
        '',
      ].join('\n'),
    ],
    ['a preflight that runs after the action', workflow([...RUN_STEP, '      - run: script/validate-takt-auth.sh'])],
  ];

  test.each(ACCEPTED)('accepts %s', (_label, content) => {
    const result = runCheck(FLAG, { 'claude.yml': content });

    expect(result.output).toContain('Claude token guard ok');
    expect(result.status).toBe(0);
  });

  test.each(REJECTED)('flags %s', (_label, content) => {
    const result = runCheck(FLAG, { 'claude.yml': content });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('claude.yml');
  });
});
