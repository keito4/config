import { run, ciRun, check, job } from './ci-waiter.test-support.mjs';
const foreign = (id, workflow = id) => run({ id, workflow_id: workflow, check_suite_id: id * 10, run_number: id });
const build = (id, suite, conclusion = 'success') =>
  check({ id, name: 'Build', check_suite: { id: suite }, conclusion });
export const identityCases = [
  ['malformed optional check ID', { checks: [check(), check({ id: -1, name: 'Optional' })] }, false],
  [
    'unknown unrelated run conclusion',
    {
      otherRuns: [foreign(30, 30), foreign(40, 40)].map((r) => ({
        ...r,
        conclusion: 'unknown',
      })),
    },
    false,
  ],
  ['current run found on inventory page two', { allRuns: [ciRun()], allSecondPage: [run()] }, true],
  [
    'new pending run on inventory page two',
    {
      allSecondPage: [
        run({
          id: 11,
          run_number: 11,
          check_suite_id: 71,
          status: 'queued',
          conclusion: null,
        }),
      ],
    },
    false,
  ],
  ['observed fallback pending check', { checks: [check({ id: 11, status: 'in_progress', conclusion: null })] }, false],
  [
    'observed CI pending check',
    {
      checks: [
        check(),
        check({
          id: 21,
          name: 'Build',
          check_suite: { id: 170 },
          status: 'queued',
          conclusion: null,
        }),
      ],
    },
    false,
  ],
  [
    'different workflow same-name failure',
    {
      otherRuns: [foreign(30), foreign(40)],
      checks: [check(), build(301, 300, 'failure'), build(401, 400)],
    },
    false,
  ],
  [
    'obsolete distinct run of same workflow',
    {
      otherRuns: [foreign(30), foreign(31, 30)],
      checks: [check(), build(301, 300, 'failure'), build(311, 310)],
    },
    true,
  ],
  ['same suite obsolete attempt', { checks: [check({ id: 9, conclusion: 'failure' }), check()] }, true],
  [
    'unrelated optional pending',
    {
      checks: [
        check(),
        check({
          id: 90,
          name: 'Optional',
          app: { id: 99, slug: 'third-party' },
          check_suite: { id: 900 },
          status: 'in_progress',
          conclusion: null,
        }),
      ],
    },
    true,
  ],
  [
    'run attempt updated during reads',
    {
      allRuns: [ciRun(), run({ run_attempt: 2, status: 'queued', conclusion: null })],
    },
    false,
  ],
  ['new successful attempt still differs from receipt', { allRuns: [ciRun(), run({ run_attempt: 2 })] }, false],
  [
    'new run during reads',
    {
      allRuns: [ciRun(), run(), run({ id: 11, run_number: 11, check_suite_id: 71 })],
    },
    false,
  ],
  ['missing mandatory current run', { allRuns: [ciRun()] }, false],
  ['unknown check suite', { checks: [check(), build(301, 300)] }, false],
  ['missing check suite metadata', { checks: [check({ check_suite: null })] }, false],
  ['missing run suite metadata', { allRuns: [ciRun(), run({ check_suite_id: null })] }, false],
  ['unknown run status', { allRuns: [ciRun(), run({ status: 'unknown' })] }, false],
  ['foreign head in complete run inventory', { allRuns: [ciRun(), run({ head_sha: 'old' })] }, false],
  ['duplicate suite in run inventory', { allRuns: [ciRun(), run(), run({ id: 11 })] }, false],
  ['missing exact gate check', { checks: [check({ id: 11 })] }, false],
  [
    'foreign job check URL',
    {
      jobs: [
        job({
          check_run_url: 'https://api.github.com/repos/foreign/repo/check-runs/10',
        }),
      ],
    },
    false,
  ],
  [
    'unknown optional check status',
    {
      checks: [
        check(),
        check({
          id: 90,
          name: 'Optional',
          app: { id: 99, slug: 'third-party' },
          check_suite: { id: 900 },
          status: 'unknown',
        }),
      ],
    },
    false,
  ],
  ['complete run inventory API error', { inventoryError: true }, false],
  ['wrong job run', { jobs: [job({ run_id: 99 })] }, false],
  ['wrong job attempt', { jobs: [job({ run_attempt: 2 })] }, false],
  [
    'different check app cannot replace mandatory gate',
    { checks: [check({ app: { id: 99, slug: 'other-app' } })] },
    false,
  ],
];
export const evolvingRerun = {
  afterChecks: {
    current: run({ run_attempt: 2, status: 'in_progress', conclusion: null }),
    checks: [check({ id: 11, status: 'in_progress', conclusion: null })],
  },
  settleAt: 1,
  settled: {
    current: run({ run_attempt: 2 }),
    jobs: [
      job({
        id: 11,
        run_attempt: 2,
        check_run_url: 'https://api.github.com/repos/fixture/repo/check-runs/11',
      }),
    ],
    checks: [check({ id: 11 })],
  },
};

export const fallbackRejectCases = {
  absent: { runs: [], secondPage: [], checks: [] },
  'missing gate despite other success': {
    jobs: [],
    checks: [check({ name: 'Optional' })],
  },
  'failed gate': {
    jobs: [job({ conclusion: 'failure' })],
    checks: [check({ conclusion: 'failure' })],
  },
  pending: {
    current: run({ status: 'in_progress', conclusion: null }),
    checks: [check({ status: 'in_progress', conclusion: null })],
  },
  'unknown status': { current: run({ status: 'unknown' }) },
  'API error': { apiError: true },
  'check API error': { checkError: true },
  disabled: {
    workflow: {
      id: 7,
      state: 'disabled_manually',
      path: '.github/workflows/quality-gate-fallback.yml',
    },
  },
  'wrong SHA': { runs: [run({ head_sha: 'old' })] },
  'fake workflow': { runs: [run({ workflow_id: 8 })] },
  'latest attempt failure': {
    current: run({ run_attempt: 2, conclusion: 'failure' }),
  },
  'stale success before newer failure': {
    runs: [run(), run({ id: 11, run_number: 11 })],
    current: run({ id: 11, run_number: 11, conclusion: 'failure' }),
  },
  'genuine old failed check': {
    checks: [check(), check({ id: 11, name: 'Build', conclusion: 'failure' })],
  },
  'gate skipped': { jobs: [job({ conclusion: 'skipped' })] },
  'missing job head': { jobs: [job({ head_sha: null })] },
  'run cancelled': { current: run({ conclusion: 'cancelled' }) },
};
export const ciRetryRejectCases = {
  'pending newer attempt': {
    ciCurrent: ciRun({
      run_attempt: 2,
      status: 'in_progress',
      conclusion: null,
    }),
  },
  'failed newer attempt': {
    ciCurrent: ciRun({ run_attempt: 2, conclusion: 'failure' }),
  },
  'absent CI': { ciRuns: [] },
  'foreign CI head': { ciRuns: [ciRun({ head_sha: 'old' })] },
  'latest CI is pending': {
    ciSecondPage: [ciRun({ id: 21, run_number: 11 })],
    ciCurrent: ciRun({
      id: 21,
      run_number: 11,
      status: 'queued',
      conclusion: null,
    }),
  },
};
