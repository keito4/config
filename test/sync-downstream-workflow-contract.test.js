const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const vm = require('vm');
const { spawnSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const workflowPath = '.github/workflows/sync-downstream.yml';

function readWorkflow() {
  return fs.readFileSync(path.join(repoPath, workflowPath), 'utf8');
}

// js-yaml は YAML 1.1 の `on:` を真偽値 true として読む。
function loadWorkflow() {
  const doc = yaml.load(readWorkflow());
  return { ...doc, on: doc.on ?? doc[true] };
}

// keito4/config#1188 の再発防止。CLAUDE_PAT が 2026-05 頃に失効してから、
// sync-downstream は保持期間内の全 run が failure だったのに誰も気付けなかった。
// 落ちるのは downstream checkout の中なので、ログに出るのは 5 job 分の
// `Bad credentials` だけで、どのシークレットを直せばよいか読み取れなかった。
//
// 文字列検索ではなく job 単位で表明する。ファイル全体を grep すると、
// ゲートが別 job へ移っても、notify から always() が消えても素通りする。
describe('sync-downstream workflow contracts', () => {
  test('installs the locked parser without lifecycle scripts before downstream credentials are checked out', () => {
    const { steps } = loadWorkflow().jobs.sync;
    const setup = steps.findIndex((step) => step.uses === './.github/actions/setup-node-ci');
    const install = steps.findIndex((step) => step.run === 'npm ci --ignore-scripts');
    const downstream = steps.findIndex((step) => step.with?.path === 'downstream');

    expect(steps[0].uses).toMatch(/^actions\/checkout@/);
    expect(steps[0].with?.token).toBeUndefined();
    expect(setup).toBeGreaterThan(0);
    expect(steps[setup].with.install).toBe('false');
    expect(install).toBeGreaterThan(setup);
    expect(downstream).toBeGreaterThan(install);
    expect(steps[install]['working-directory']).toBeUndefined();
    expect(steps[install].env).toBeUndefined();
  });

  test('validates the downstream token before any matrix job runs', () => {
    const { jobs } = loadWorkflow();
    const step = jobs.preflight.steps.find((s) => s.name === 'Validate downstream token');

    expect(step).toBeDefined();
    expect(step.env.DOWNSTREAM_TOKEN).toBe('${{ secrets.DOWNSTREAM_SYNC_TOKEN || secrets.CLAUDE_PAT }}');
    // 未設定・失効・権限不足・API 到達不能はそれぞれ対処が違う。区別せずに
    // 一括で「失効」と言うと、直せない相手を直そうとすることになる。
    expect(step.run).toMatch(/api\.github\.com\/repos\//);
    expect(step.run).toMatch(/permissions\.push/);
    expect(step.run).toMatch(/401\)/);
    expect(step.run).toMatch(/000\)/);
    expect(step.run).toMatch(/403 \| 404\)/);
    expect(step.run).toMatch(/429 \| 5\?\?\)/);

    // 各分岐は必ず落ちること。`exit 1` を1つ落とすだけで、検証を通過したように
    // 見えて matrix へ進む — preflight を入れた意味が消える。
    // match() は一致が無いと null を返すため、.length を直接呼ぶと TypeError になる。
    // 一致数 0 は「アサーション失敗」として扱いたいのでまず [] にフォールバックする。
    const errors = (step.run.match(/::error::/g) || []).length;
    const exits = (step.run.match(/^\s*exit 1$/gm) || []).length;
    expect(errors).toBeGreaterThanOrEqual(6);
    expect(exits).toBe(errors);
  });

  test('gates plan and sync behind the preflight check', () => {
    const { jobs } = loadWorkflow();

    expect(jobs.plan.needs).toBe('preflight');
    expect(jobs.sync.needs).toEqual(['preflight', 'plan']);
  });

  test('detects token expiry without waiting for a template push', () => {
    const { on, jobs } = loadWorkflow();

    expect(on.schedule).toHaveLength(1);
    expect(on.schedule[0].cron).toMatch(/^[\d*/ ,-]+$/);
    // 定期実行はトークンの生存確認だけ。勝手に downstream PR を作らせない。
    expect(jobs.plan.if).toBe("github.event_name != 'schedule'");
  });

  test('reports a failure instead of staying silently red', () => {
    const { jobs } = loadWorkflow();

    expect(jobs.notify.needs).toEqual(['preflight', 'plan', 'sync']);
    // always() が無いと、preflight 失敗で後続が skip された run では notify も
    // skip され、元の「黙って赤い」状態に戻る。
    expect(jobs.notify.if).toContain('always()');
    expect(jobs.notify.if).toContain("contains(needs.*.result, 'failure')");
    expect(jobs.notify.permissions.issues).toBe('write');

    const run = jobs.notify.steps[0].run;
    expect(run).toContain('gh issue create');
    // 同じ失敗で issue を積み上げない。
    expect(run).toContain('gh issue list');
  });

  test('keeps the downstream checkout and PR creation on the validated secret', () => {
    const { jobs } = loadWorkflow();

    const token = jobs.preflight.steps.find((s) => s.name === 'Validate downstream token').env.DOWNSTREAM_TOKEN;
    const patUses = jobs.sync.steps.filter((s) => s.with && s.with.token === token);
    expect(patUses).toHaveLength(2);
  });
});

// Execute the checked-in preflight shell with synthetic secrets and a local
// curl stub. No credentials or network are used by these regression cases.
describe('downstream credential selection', () => {
  let tempDir;
  const secrets = { DOWNSTREAM_SYNC_TOKEN: 'dedicated-test-value', CLAUDE_PAT: 'legacy-test-value' };
  const evaluate = (expression, values) => vm.runInNewContext(expression.slice(3, -2), { secrets: values });

  beforeEach(() => {
    const contextDir = path.join(repoPath, '.context');
    fs.mkdirSync(contextDir, { recursive: true });
    tempDir = fs.mkdtempSync(path.join(contextDir, 'sync-auth-test-'));
    fs.writeFileSync(
      path.join(tempDir, 'curl'),
      `#!/bin/bash
printf '%s\\n' "$@" >> "$RUNNER_TEMP/curl-args"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) printf '{"permissions":{"push":true}}' > "$2"; shift ;;
    -D) printf 'x-oauth-scopes: %s\\r\\n' "$TEST_OAUTH_SCOPES" > "$2"; shift ;;
  esac
  shift
done
printf '%s' "$TEST_HTTP_STATUS"
`,
      { mode: 0o755 },
    );
  });

  afterEach(() => fs.rmSync(tempDir, { recursive: true, force: true }));

  function runPreflight(values, status = '200', scopes = '') {
    const step = loadWorkflow().jobs.preflight.steps.find((s) => s.name === 'Validate downstream token');
    const env = Object.fromEntries(Object.entries(step.env).map(([key, value]) => [key, evaluate(value, values)]));
    const script = step.run.replaceAll('${{ github.repository }}', 'keito4/config');
    const result = spawnSync('bash', ['--noprofile', '--norc', '-eo', 'pipefail', '-c', script], {
      cwd: repoPath,
      encoding: 'utf8',
      env: {
        ...process.env,
        ...env,
        PATH: `${tempDir}:${process.env.PATH}`,
        RUNNER_TEMP: tempDir,
        TEST_HTTP_STATUS: status,
        TEST_OAUTH_SCOPES: scopes,
      },
    });
    const argsPath = path.join(tempDir, 'curl-args');
    return { ...result, args: fs.existsSync(argsPath) ? fs.readFileSync(argsPath, 'utf8') : '' };
  }

  test.each([
    ['dedicated', secrets, 'DOWNSTREAM_SYNC_TOKEN', secrets.DOWNSTREAM_SYNC_TOKEN],
    ['legacy', { ...secrets, DOWNSTREAM_SYNC_TOKEN: '' }, 'CLAUDE_PAT', secrets.CLAUDE_PAT],
  ])('uses the %s token for validation, checkout, and PR creation', (_, values, name, token) => {
    const result = runPreflight(values);
    expect(result.status).toBe(0);
    expect(result.args).toContain(`Authorization: Bearer ${token}`);
    expect(result.stdout).toContain(`${name} can push`);
    const consumers = loadWorkflow().jobs.sync.steps.filter((s) => s.with?.token);
    expect(consumers).toHaveLength(2);
    expect(consumers.map((s) => evaluate(s.with.token, values))).toEqual([token, token]);
    expect(result.stdout).not.toContain(token);
  });

  test('fails before calling GitHub when both secrets are missing', () => {
    const result = runPreflight({ DOWNSTREAM_SYNC_TOKEN: '', CLAUDE_PAT: '' });
    expect(result.status).toBe(1);
    expect(result.stdout).toContain('DOWNSTREAM_SYNC_TOKEN');
    expect(result.stdout).toContain('CLAUDE_PAT');
    expect(result.args).toBe('');
  });

  test.each(['401', '403', '404', '429', '500', '000'])(
    'names the selected secret on HTTP %s without trying the fallback',
    (status) => {
      const result = runPreflight(secrets, status);
      expect(result.status).toBe(1);
      expect(result.stdout).toContain('DOWNSTREAM_SYNC_TOKEN');
      expect(result.args.match(/Authorization: Bearer/g)).toHaveLength(1);
      expect(result.args).not.toContain(secrets.CLAUDE_PAT);
      expect(result.stdout).not.toContain(secrets.DOWNSTREAM_SYNC_TOKEN);
    },
  );

  test('identifies an expired legacy token when the dedicated secret is absent', () => {
    const result = runPreflight({ ...secrets, DOWNSTREAM_SYNC_TOKEN: '' }, '401');
    expect(result.status).toBe(1);
    expect(result.stdout).toContain('CLAUDE_PAT was rejected');
  });

  test.each([
    ['repo, workflow', 0],
    ['repo', 1],
  ])('preserves classic PAT scope validation for %s', (scopes, status) => {
    const result = runPreflight(secrets, '200', scopes);
    expect(result.status).toBe(status);
    expect(result.stdout).toContain('DOWNSTREAM_SYNC_TOKEN');
    if (status === 1) expect(result.stdout).toContain("missing the 'workflow' scope");
  });

  test('failure notification directs operators to the selected secret rather than replacing CLAUDE_PAT', () => {
    const notification = loadWorkflow().jobs.notify.steps[0];
    expect(evaluate(notification.env.DOWNSTREAM_TOKEN_NAME, secrets)).toBe('DOWNSTREAM_SYNC_TOKEN');
    expect(evaluate(notification.env.DOWNSTREAM_TOKEN_NAME, { ...secrets, DOWNSTREAM_SYNC_TOKEN: '' })).toBe(
      'CLAUDE_PAT',
    );
    expect(notification.run).toContain('$DOWNSTREAM_TOKEN_NAME');
    expect(notification.run).not.toContain('gh secret set CLAUDE_PAT');
  });
});
