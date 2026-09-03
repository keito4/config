const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

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
  test('validates the downstream token before any matrix job runs', () => {
    const { jobs } = loadWorkflow();
    const step = jobs.preflight.steps.find((s) => s.name === 'Validate downstream token');

    expect(step).toBeDefined();
    expect(step.env.CLAUDE_PAT).toBe('${{ secrets.CLAUDE_PAT }}');
    // 未設定・失効・権限不足・API 到達不能はそれぞれ対処が違う。区別せずに
    // 一括で「失効」と言うと、直せない相手を直そうとすることになる。
    expect(step.run).toMatch(/api\.github\.com\/repos\//);
    expect(step.run).toMatch(/permissions\.push/);
    expect(step.run).toMatch(/401\)/);
    expect(step.run).toMatch(/000\)/);
    expect(step.run.match(/::error::/g).length).toBeGreaterThanOrEqual(5);
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

    const patUses = jobs.sync.steps.filter((s) => s.with && s.with.token === '${{ secrets.CLAUDE_PAT }}');
    expect(patUses).toHaveLength(2);
  });
});
