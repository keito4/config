import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
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
if (Number(fs.readFileSync(process.env.CLOCK, 'utf8')) < (f.pendingUntil ?? 0)) {
 const pending = r => ({...r, status:'in_progress', conclusion:null});
 for (const key of ['ciRuns','runs','jobs','checks']) f[key] = f[key].map(pending);
 f.ciCurrent = pending(f.ciCurrent); f.current = pending(f.current);
}
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
if (Array.isArray(result)) {
 const key = ['workflow_runs','jobs','check_runs'].find(k => result.some(p => Object.hasOwn(p,k)));
 const total = result.reduce((n,p) => n + p[key].length, 0);
 for (const page of result) page.total_count = total;
 if (f.violationEndpoint && endpoint.includes(f.violationEndpoint)) {
  if (f.violation === 'truncated') for (const page of result) page.total_count++;
  if (f.violation === 'missing count') for (const page of result) delete page.total_count;
  if (f.violation === 'invalid collection') result[0][key] = {};
  if (f.violation === 'duplicate row') { result[0][key].push(result[0][key][0]); for (const page of result) page.total_count++; }
 }
}
process.stdout.write(JSON.stringify(result));
`;
function execute(options = {}) {
  mkdirSync('.context', { recursive: true });
  const dir = mkdtempSync(resolve('.context/ci-waiter-'));
  const review = readFileSync('.github/workflows/claude-code-review.yml', 'utf8');
  const waitJob = review.split('\n  check-ci-status:\n')[1].split(/\n {2}[\w-]+:\n/)[0];
  const permissions = waitJob.match(/\n {4}permissions:\n((?: {6}.*\n)+)/)[1];
  const fixture = {
    ciWorkflow: {
      id: 17,
      state: 'active',
      path: '.github/workflows/ci.yml',
    },
    ciRuns: [ciRun()],
    ciSecondPage: [],
    ciCurrent: ciRun(),
    actionsRead: / {6}actions: read\n/.test(permissions),
    workflow: {
      id: 7,
      state: 'active',
      path: '.github/workflows/quality-gate-fallback.yml',
    },
    runs: [run()],
    secondPage: [],
    current: run(),
    checks: [check()],
    jobs: [job()],
    ...options,
  };
  writeFileSync(join(dir, 'fixture.json'), JSON.stringify(fixture));
  writeFileSync(join(dir, 'clock'), '0');
  writeFileSync(join(dir, 'gh'), stub, { mode: 0o755 });
  writeFileSync(
    join(dir, 'sleep'),
    `#!/usr/bin/env node
const fs = require('node:fs');
fs.writeFileSync(process.env.CLOCK, String(Number(fs.readFileSync(process.env.CLOCK, 'utf8')) + Number(process.argv[2])));
`,
    { mode: 0o755 },
  );
  const output = join(dir, 'output');
  const result = spawnSync('bash', ['script/wait-ci-checks.sh', 'fixture/repo', sha], {
    encoding: 'utf8',
    timeout: options.useConfiguredTimeout ? 15000 : 5000,
    env: {
      ...process.env,
      PATH: dir + ':' + process.env.PATH,
      FIXTURE: join(dir, 'fixture.json'),
      CALLS: join(dir, 'calls'),
      CLOCK: join(dir, 'clock'),
      GITHUB_OUTPUT: output,
      MAX_WAIT_TIME: options.useConfiguredTimeout ? '' : '2',
      POLL_INTERVAL: String(options.pollInterval ?? 1),
      QUALITY_GATE_MISSING_GRACE: '0',
    },
  });
  try {
    assert.equal(result.status, 0, result.stderr);
    const passed = readFileSync(output, 'utf8').trim();
    const calls = readFileSync(join(dir, 'calls'), 'utf8');
    return {
      passed,
      calls,
      elapsed: Number(readFileSync(join(dir, 'clock'), 'utf8')),
    };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
export { run, ciRun, check, job, execute };
