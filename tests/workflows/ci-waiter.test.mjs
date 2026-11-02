import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { run, check, execute } from './ci-waiter.test-support.mjs';
import { fallbackRejectCases, ciRetryRejectCases } from './ci-waiter-cases.test-support.mjs';

test('waiter: configured budget permits a 70-minute pending CI', () => {
  const result = execute({
    useConfiguredTimeout: true,
    pollInterval: 300,
    pendingUntil: 4200,
  });
  assert.equal(result.passed, 'ci_passed=true');
  assert.equal(result.elapsed, 4200);
});
test('waiter: unfinished CI fails at the bounded 75-minute deadline', () => {
  const result = execute({
    useConfiguredTimeout: true,
    pollInterval: 300,
    pendingUntil: 4800,
  });
  assert.equal(result.passed, 'ci_passed=false');
  assert.equal(result.elapsed, 4500);
});
test('waiter: an explicit shorter caller timeout remains effective', () => {
  const result = execute({ pendingUntil: 2400 });
  assert.equal(result.passed, 'ci_passed=false');
  assert.equal(result.elapsed, 2);
});
test('waiter: consumer job encloses the budget and model job stays unchanged', () => {
  const review = readFileSync('.github/workflows/claude-code-review.yml', 'utf8');
  const checkJob = review.split('\n  check-ci-status:\n')[1].split('\n  claude-review:\n')[0];
  const modelJob = review.split('\n  claude-review:\n')[1];
  assert.match(checkJob, / {4}timeout-minutes: 80\b/);
  assert.match(modelJob, / {4}timeout-minutes: 20\b/);
});

test('waiter: exact workflow, SHA, attempt and successful gate passes', () => {
  const result = execute();
  assert.equal(result.passed, 'ci_passed=true');
  assert.match(result.calls, /quality-gate-fallback.yml/);
  assert.match(result.calls, /attempts\/1\/jobs/);
});
for (const [name, options] of Object.entries(fallbackRejectCases))
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
      check_suite: { id: 300 },
      status: state === 'in_progress' ? state : 'completed',
      conclusion: state === 'in_progress' ? null : state,
    }),
  );
  assert.equal(
    execute({
      checks: [check(), ...checks],
      otherRuns: [run({ id: 30, workflow_id: 30, check_suite_id: 300 })],
    }).passed,
    'ci_passed=true',
  );
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
    execute({
      runs: [],
      checks: [check({ app: { id: 99, slug: 'other-app' } })],
    }).passed,
    'ci_passed=false',
  );
});

for (const [name, options] of Object.entries(ciRetryRejectCases))
  test(`waiter: old fallback success rejects ${name}`, () => assert.equal(execute(options).passed, 'ci_passed=false'));

for (const endpoint of ['/workflows/17/runs?', '/workflows/7/runs?', '/attempts/', '/check-runs']) {
  for (const violation of ['truncated', 'missing count', 'invalid collection', 'duplicate row']) {
    test(`waiter: rejects ${violation} at ${endpoint}`, () =>
      assert.equal(execute({ violationEndpoint: endpoint, violation }).passed, 'ci_passed=false'));
  }
}
