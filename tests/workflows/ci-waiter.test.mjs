import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import process from 'node:process';

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
const ciRun = (extra = {}) => run({ id: 20, workflow_id: 17, ...extra });
const check = (extra = {}) => ({
  id: 10,
  name: 'Quality Gate',
  head_sha: sha,
  app: { id: 15368, slug: 'github-actions' },
  status: 'completed',
  conclusion: 'success',
  ...extra,
});
const job = (extra = {}) => ({
  id: 10,
  name: 'Quality Gate',
  head_sha: sha,
  status: 'completed',
  conclusion: 'success',
  ...extra,
});
const stub = `#!/usr/bin/env node
const fs = require('node:fs'), cp = require('node:child_process');
const f = JSON.parse(fs.readFileSync(process.env.FIXTURE));
const args = process.argv.slice(2), endpoint = args.find(x => x.startsWith('repos/'));
fs.appendFileSync(process.env.CALLS, JSON.stringify(args) + '\\n');
let result;
if (endpoint.includes('/actions/') && !f.actionsRead) process.exit(3);
if (f.apiError || (f.checkError && endpoint.includes('/check-runs'))) process.exit(1);
if (endpoint.includes('/check-runs')) result = args.includes('--slurp') ? [{check_runs:f.checks}] : {check_runs:f.checks};
else if (endpoint.includes('/workflows/17/runs?')) result = [{workflow_runs:f.ciRuns}, {workflow_runs:f.ciSecondPage}];
else if (endpoint.endsWith('/ci.yml')) result = f.ciWorkflow;
else if (endpoint.endsWith('/actions/runs/' + f.ciCurrent.id)) result = f.ciCurrent;
else if (endpoint.includes('/attempts/')) {
 if (!endpoint.includes('/attempts/' + f.current.run_attempt + '/')) process.exit(2);
 result = [{jobs:f.jobs}];
} else if (endpoint.includes('/runs?')) {
 if (!args.includes('--paginate') || !args.includes('--slurp')) process.exit(2);
 result = [{workflow_runs:f.runs}, {workflow_runs:f.secondPage}];
} else if (endpoint.includes('/actions/runs/')) result = f.current;
else if (endpoint.endsWith('/quality-gate-fallback.yml')) result = f.workflow;
else process.exit(2);
const jq = args.indexOf('--jq');
if (jq >= 0) { const r = cp.spawnSync('jq',['-r',args[jq+1]],{input:JSON.stringify(result),encoding:'utf8'}); process.stdout.write(r.stdout); process.exit(r.status); }
process.stdout.write(JSON.stringify(result));
`;
function execute(options = {}) {
  mkdirSync('.context', { recursive: true });
  const dir = mkdtempSync(resolve('.context/ci-waiter-'));
  const review = readFileSync('.github/workflows/claude-code-review.yml', 'utf8');
  const waitJob = review.split('\n  check-ci-status:\n')[1].split(/\n {2}[\w-]+:\n/)[0];
  const permissions = waitJob.match(/\n {4}permissions:\n((?: {6}.*\n)+)/)[1];
  const fixture = {
    ciWorkflow: { id: 17, state: 'active', path: '.github/workflows/ci.yml' },
    ciRuns: [ciRun()],
    ciSecondPage: [],
    ciCurrent: ciRun(),
    actionsRead: / {6}actions: read\n/.test(permissions),
    workflow: { id: 7, state: 'active', path: '.github/workflows/quality-gate-fallback.yml' },
    runs: [run()],
    secondPage: [],
    current: run(),
    checks: [check()],
    jobs: [job()],
    ...options,
  };
  writeFileSync(join(dir, 'fixture.json'), JSON.stringify(fixture));
  writeFileSync(join(dir, 'gh'), stub, { mode: 0o755 });
  writeFileSync(join(dir, 'sleep'), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
  const output = join(dir, 'output');
  const result = spawnSync('bash', ['script/wait-ci-checks.sh', 'fixture/repo', sha], {
    encoding: 'utf8',
    timeout: 5000,
    env: {
      ...process.env,
      PATH: dir + ':' + process.env.PATH,
      FIXTURE: join(dir, 'fixture.json'),
      CALLS: join(dir, 'calls'),
      GITHUB_OUTPUT: output,
      MAX_WAIT_TIME: '2',
      POLL_INTERVAL: '1',
      QUALITY_GATE_MISSING_GRACE: '0',
    },
  });
  try {
    assert.equal(result.status, 0, result.stderr);
    const passed = readFileSync(output, 'utf8').trim();
    const calls = readFileSync(join(dir, 'calls'), 'utf8');
    return { passed, calls };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
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
