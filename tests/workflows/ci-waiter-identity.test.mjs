import assert from 'node:assert/strict';
import test from 'node:test';
import { execute } from './ci-waiter.test-support.mjs';
import { identityCases, evolvingRerun } from './ci-waiter-cases.test-support.mjs';
for (const [name, options, expected] of identityCases) {
  test(`waiter identity: ${name}`, () => assert.equal(execute(options).passed, `ci_passed=${expected}`));
}
test('waiter identity: observed rerun stays pending then completes on its new attempt', () => {
  const result = execute(evolvingRerun);
  assert.equal(result.passed, 'ci_passed=true');
  assert.equal(result.elapsed, 1);
  assert.match(result.calls, /attempts\/2\/jobs/);
});
for (const violation of ['truncated', 'missing count', 'inconsistent count', 'invalid collection', 'duplicate row']) {
  test(`waiter identity: complete run inventory rejects ${violation}`, () =>
    assert.equal(execute({ violationEndpoint: '/actions/runs?', violation }).passed, 'ci_passed=false'));
}
