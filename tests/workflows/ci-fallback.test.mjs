import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { paths, sha, run, execute } from './ci-fallback.test-support.mjs';
import { execute as executeWaiter } from './ci-waiter.test-support.mjs';

for (const file of paths) {
  test(`${file}: permits 60 minute CI and fails at the bounded 70 minute deadline`, async () => {
    const completed = await execute(file, { succeedAfterMs: 3600000 });
    assert.deepEqual(completed.failures, []);
    assert.equal(completed.now, 3600000);
    const unfinished = await execute(file, { succeedAfterMs: 4200001 });
    assert.match(unfinished.failures[0], /4200 seconds/);
    assert.equal(unfinished.now, 4200000);
    assert.match(readFileSync(file, 'utf8'), / {4}timeout-minutes: 75\n/);
  });

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
    'truncated response': { totalCount: 2 },
    'missing response count': { totalCount: undefined },
    'duplicate response rows': { runs: [run(), run()] },
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

for (const [name, options, passed, elapsed] of [
  ['40 minute success', { useConfiguredTimeout: true, pollInterval: 300, pendingUntil: 2400 }, 'true', 2400],
  ['75 minute timeout', { useConfiguredTimeout: true, pollInterval: 300, pendingUntil: 4800 }, 'false', 4500],
  ['explicit shorter timeout', { pendingUntil: 2400 }, 'false', 2],
]) {
  test(`actual waiter: ${name}`, () => {
    const result = executeWaiter(options);
    assert.equal(result.passed, `ci_passed=${passed}`);
    assert.equal(result.elapsed, elapsed);
  });
}
