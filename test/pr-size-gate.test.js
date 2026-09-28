'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const yaml = require('js-yaml');

const gatePaths = [
  '.github/actions/pr-size-check/action.yml',
  '.github/workflows/quality-gate-fallback.yml',
  'templates/workflows/quality-gate-fallback.yml',
  'templates/workflows/pr-size-gate.yml',
];

/**
 * Execute the shipped GitHub script with a PR payload and read-only API doubles.
 * @param {string} file - Action or workflow path.
 * @param {object} options - PR author, size, runner and live label overrides.
 * @returns {Promise<object>} Captured Actions result and API calls.
 */
async function runGate(file, options = {}) {
  const document = yaml.load(fs.readFileSync(path.join(__dirname, '..', file), 'utf8'));
  const steps = document.runs?.steps ?? Object.values(document.jobs).flatMap((job) => job.steps);
  const script = steps.find((step) => ['Check PR Size', 'Enforce PR size'].includes(step.name)).with.script;
  const inputs = { 'max-lines': '400', 'max-files': '25', 'override-label': 'size/override' };
  const source = script.replace(/\$\{\{ inputs\.([\w-]+) \}\}/g, (_, name) => inputs[name]);
  const core = { info: jest.fn(), warning: jest.fn(), setFailed: jest.fn() };
  const denied = () => Promise.reject(Object.assign(new Error('Forbidden'), { status: 403 }));
  const issues = {
    listLabelsOnIssue: jest.fn(denied),
    removeLabel: jest.fn(denied),
    addLabels: jest.fn(denied),
    listComments: jest.fn(denied),
    createComment: jest.fn(denied),
  };
  if (options.liveLabels) {
    issues.listLabelsOnIssue.mockResolvedValue({ data: options.liveLabels });
  }
  const pullRequest = {
    user: { login: options.author ?? 'keito4' },
    additions: options.lines ?? 1393,
    deletions: 0,
    changed_files: options.files ?? 2,
    labels: [],
    head: { ref: 'dependabot/npm_and_yarn/dev-minor-example' },
  };
  const context = {
    actor: options.actor ?? 'keito4',
    payload: { pull_request: pullRequest },
    repo: { owner: 'keito4', repo: 'config' },
    issue: { number: 1301 },
  };
  await new vm.Script(`(async () => { ${source} })()`).runInNewContext({
    context,
    core,
    github: { rest: { issues } },
  });
  return { core, issues };
}

describe.each(gatePaths)('%s', (file) => {
  test.each(['dependabot[bot]', 'keito4'])(
    'allows an oversized Dependabot PR with a read-only token when run by %s',
    async (actor) => {
      const { core, issues } = await runGate(file, { author: 'dependabot[bot]', actor });
      expect(core.setFailed).not.toHaveBeenCalled();
      expect(core.info).toHaveBeenCalledWith(expect.stringContaining('Dependabot'));
      for (const api of Object.values(issues)) {
        expect(api).not.toHaveBeenCalled();
      }
    },
  );

  test('allows Dependabot updates beyond the file limit', async () => {
    const { core } = await runGate(file, { author: 'dependabot[bot]', lines: 100, files: 26 });
    expect(core.setFailed).not.toHaveBeenCalled();
  });

  test.each(['keito4', 'renovate[bot]'])(
    'still rejects oversized PRs by %s despite a Dependabot actor and branch name',
    async (author) => {
      const { core } = await runGate(file, { author, actor: 'dependabot[bot]' });
      expect(core.setFailed).toHaveBeenCalledWith(expect.stringContaining('1393 lines'));
    },
  );

  test('allows ordinary PRs exactly at both limits', async () => {
    const { core } = await runGate(file, { lines: 400, files: 25 });
    expect(core.setFailed).not.toHaveBeenCalled();
  });

  test.each([
    { lines: 401, files: 1 },
    { lines: 1, files: 26 },
  ])('rejects ordinary PRs just beyond a limit: %j', async (size) => {
    const { core } = await runGate(file, size);
    expect(core.setFailed).toHaveBeenCalledTimes(1);
  });

  test('preserves a live reviewer override absent from the event snapshot', async () => {
    const { core } = await runGate(file, { liveLabels: [{ name: 'size/override' }] });
    expect(core.setFailed).not.toHaveBeenCalled();
    expect(core.warning).toHaveBeenCalledWith(expect.stringContaining('size/override'));
  });
});
