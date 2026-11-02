import assert from 'node:assert/strict';
import test from 'node:test';
import { run, ciRun, check, job, execute } from './ci-waiter.test-support.mjs';

test('waiter: exact workflow, SHA, attempt and successful gate passes', () => {
  const result = execute();
  assert.equal(result.passed, 'ci_passed=true');
  assert.match(result.calls, /quality-gate-fallback.yml/);
  assert.match(result.calls, /attempts\/1\/jobs/);
});
for (const [name, options] of Object.entries({
  absent: { runs: [], secondPage: [], checks: [] },
  'missing gate despite other success': { jobs: [], checks: [check({ name: 'Optional' })] },
  'failed gate': { jobs: [job({ conclusion: 'failure' })], checks: [check({ conclusion: 'failure' })] },
  pending: {
    current: run({ status: 'in_progress', conclusion: null }),
    checks: [check({ status: 'in_progress', conclusion: null })],
  },
  'unknown status': { current: run({ status: 'unknown' }) },
  'API error': { apiError: true },
  'check API error': { checkError: true },
  disabled: { workflow: { id: 7, state: 'disabled_manually', path: '.github/workflows/quality-gate-fallback.yml' } },
  'wrong SHA': { runs: [run({ head_sha: 'old' })] },
  'fake workflow': { runs: [run({ workflow_id: 8 })] },
  'latest attempt failure': { current: run({ run_attempt: 2, conclusion: 'failure' }) },
  'stale success before newer failure': {
    runs: [run(), run({ id: 11, run_number: 11 })],
    current: run({ id: 11, run_number: 11, conclusion: 'failure' }),
  },
  'genuine old failed check': { checks: [check(), check({ id: 11, name: 'Build', conclusion: 'failure' })] },
  'gate skipped': { jobs: [job({ conclusion: 'skipped' })] },
  'missing job head': { jobs: [job({ head_sha: null })] },
  'run cancelled': { current: run({ conclusion: 'cancelled' }) },
}))
  test(`waiter: rejects ${name}`, () => assert.equal(execute(options).passed, 'ci_passed=false'));
test('waiter: pagination selects current run from page two', () => {
  const result = execute({
    runs: [run({ created_at: '2025-01-01T00:00:00Z' })],
    secondPage: [run({ id: 11 })],
    current: run({ id: 11 }),
  });
  assert.equal(result.passed, 'ci_passed=true');
  assert.match(result.calls, /runs\/11/);
});
test('waiter: keeps optional pending, skipped and neutral semantics', () => {
  const checks = ['in_progress', 'skipped', 'neutral'].map((state, i) =>
    check({
      id: 20 + i,
      name: `Optional ${i}`,
      status: state === 'in_progress' ? state : 'completed',
      conclusion: state === 'in_progress' ? null : state,
    }),
  );
  assert.equal(execute({ checks }).passed, 'ci_passed=true');
});
test('waiter: superseded failure does not reject current success', () => {
  assert.equal(execute({ checks: [check({ id: 9, conclusion: 'failure' }), check()] }).passed, 'ci_passed=true');
});

test('waiter: a newer successful attempt uses its own jobs', () => {
  const result = execute({ current: run({ run_attempt: 2 }) });
  assert.equal(result.passed, 'ci_passed=true');
  assert.match(result.calls, /attempts\/2\/jobs/);
});
test('waiter: a fake app gate cannot replace the real workflow', () => {
  assert.equal(
    execute({ runs: [], checks: [check({ app: { id: 99, slug: 'other-app' } })] }).passed,
    'ci_passed=false',
  );
});

for (const [name, options] of Object.entries({
  'pending newer attempt': { ciCurrent: ciRun({ run_attempt: 2, status: 'in_progress', conclusion: null }) },
  'failed newer attempt': { ciCurrent: ciRun({ run_attempt: 2, conclusion: 'failure' }) },
  'absent CI': { ciRuns: [] },
  'foreign CI head': { ciRuns: [ciRun({ head_sha: 'old' })] },
  'latest CI is pending': {
    ciSecondPage: [ciRun({ id: 21, run_number: 11 })],
    ciCurrent: ciRun({ id: 21, run_number: 11, status: 'queued', conclusion: null }),
  },
}))
  test(`waiter: old fallback success rejects ${name}`, () => assert.equal(execute(options).passed, 'ci_passed=false'));

for (const endpoint of ['/workflows/17/runs?', '/workflows/7/runs?', '/attempts/', '/check-runs']) {
  for (const violation of ['truncated', 'missing count', 'invalid collection', 'duplicate row']) {
    test(`waiter: rejects ${violation} at ${endpoint}`, () =>
      assert.equal(execute({ violationEndpoint: endpoint, violation }).passed, 'ci_passed=false'));
  }
}
