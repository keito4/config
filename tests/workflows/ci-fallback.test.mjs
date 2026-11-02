import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import test from 'node:test';

const paths = ['.github/workflows/quality-gate-fallback.yml', 'templates/workflows/quality-gate-fallback.yml'].filter(
  existsSync,
);
assert.ok(paths.length, 'Run from the repository root');
const sha = 'a'.repeat(40);
const run = (extra = {}) => ({
  id: 10,
  workflow_id: 7,
  head_sha: sha,
  created_at: '2026-01-01T00:00:00Z',
  run_number: 10,
  run_attempt: 1,
  status: 'completed',
  conclusion: 'success',
  ...extra,
});
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;

async function execute(file, options = {}) {
  const source = readFileSync(file, 'utf8').split('      - name: Check if CI workflow ran\n')[1];
  const script = source
    .split('          script: |\n')[1]
    .split('\n      - name:')[0]
    .split('\n')
    .map((line) => line.slice(12))
    .join('\n');
  let now = 0;
  let polls = 0;
  const failures = [],
    calls = [];
  const context = {
    repo: { owner: 'fixture', repo: 'repo' },
    sha: 'merge-sha',
    runId: 99,
    payload: { pull_request: { head: { sha } } },
  };
  const core = {
    info() {},
    warning() {},
    setOutput() {},
    setFailed(message) {
      failures.push(message);
    },
  };
  const actions = {
    async getWorkflow(args) {
      calls.push(['workflow', args]);
      if (options.apiError) throw new Error('fixture API failure');
      return {
        data: { id: 7, path: '.github/workflows/ci.yml', state: options.disabled ? 'disabled_manually' : 'active' },
      };
    },
    async listWorkflowRuns(args) {
      calls.push(['list', args]);
      return { data: { workflow_runs: args.page === 2 ? (options.secondPage ?? []) : (options.runs ?? [run()]) } };
    },
    async listWorkflowRunsForRepo() {
      return { data: { workflow_runs: options.runs ?? [run({ name: 'CI' })] } };
    },
    async getWorkflowRun(args) {
      calls.push(['get', args]);
      polls++;
      if (options.getError) throw new Error('fixture run API failure');
      return {
        data:
          options.current ??
          (options.transition && polls === 1
            ? run({ status: 'in_progress', conclusion: null })
            : [...(options.runs ?? [run()]), ...(options.secondPage ?? [])].find((r) => r.id === args.run_id)),
      };
    },
  };
  const github = {
    rest: { actions },
    async paginate(method, args) {
      const all = [];
      for (let page = 1; ; page++) {
        const result = (await method({ ...args, page })).data.workflow_runs;
        all.push(...result);
        if (result.length < 100) return all;
      }
    },
  };
  await new AsyncFunction('github', 'core', 'context', 'setTimeout', 'Date', script)(
    github,
    core,
    context,
    (done, ms) => {
      now += ms;
      done();
    },
    { now: () => now, parse: Date.parse },
  );
  return { failures, calls, now };
}

for (const file of paths) {
  test(`${file}: only exact head and workflow success passes`, async () => {
    const result = await execute(file);
    assert.deepEqual(result.failures, []);
    assert.ok(result.calls.some(([type, args]) => type === 'list' && args.head_sha === sha && args.workflow_id === 7));
  });
  for (const conclusion of ['failure', 'cancelled', 'timed_out', 'skipped', 'neutral', null]) {
    test(`${file}: rejects completed ${conclusion}`, async () =>
      assert.ok((await execute(file, { runs: [run({ conclusion })] })).failures.length));
  }
  for (const [name, options] of Object.entries({
    absent: { runs: [] },
    pending: { runs: [run({ status: 'in_progress', conclusion: null })] },
    disabled: { disabled: true },
    'API error': { apiError: true },
    'run API error': { getError: true },
    'wrong SHA': { runs: [run({ head_sha: 'old' })] },
    'fake workflow': { runs: [run({ workflow_id: 8, name: 'CI' })] },
    'unknown status': { runs: [run({ status: 'unknown' })] },
    'new failure masks old success': { runs: [run(), run({ id: 11, run_number: 11, conclusion: 'failure' })] },
    'new pending masks old success': {
      runs: [run(), run({ id: 11, run_number: 11, status: 'queued', conclusion: null })],
    },
    'latest attempt': { current: run({ run_attempt: 2, conclusion: 'failure' }) },
    'changed run identity': { current: run({ head_sha: 'other' }) },
  }))
    test(`${file}: rejects ${name}`, async () => assert.ok((await execute(file, options)).failures.length));
  test(`${file}: polls pending until success`, async () => {
    const result = await execute(file, { transition: true });
    assert.deepEqual(result.failures, []);
    assert.ok(result.now >= 30000);
  });
  test(`${file}: inspects all pages and latest created run`, async () => {
    const result = await execute(file, {
      runs: Array.from({ length: 100 }, (_, i) => run({ id: i + 100, created_at: '2025-01-01T00:00:00Z' })),
      secondPage: [run({ id: 11, conclusion: 'failure' })],
    });
    assert.ok(result.failures.length);
    assert.ok(result.calls.some(([type, args]) => type === 'list' && args.page === 2));
  });
}
