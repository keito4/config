const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const workflows = ['.github/workflows/claude.yml', 'templates/workflows/claude.yml'];

describe.each(workflows)('%s finalizes queued Issues', (file) => {
  const workflow = yaml.load(fs.readFileSync(path.join(__dirname, '..', file), 'utf8'));

  async function finalize({ complete = 'true', result = 'success', state = 'open', labels = ['claude-working'] } = {}) {
    const job = workflow.jobs['finalize-issue'];
    expect(job).toBeDefined();
    const issues = {
      get: jest.fn().mockResolvedValue({ data: { state, labels: labels.map((name) => ({ name })) } }),
      getLabel: jest.fn().mockRejectedValue({ status: 404 }),
      createLabel: jest.fn(),
      addLabels: jest.fn(),
      removeLabel: jest.fn(),
    };
    const core = { setFailed: jest.fn(), info: jest.fn() };
    const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
    await new AsyncFunction('github', 'context', 'core', 'process', job.steps[0].with.script)(
      { rest: { issues } },
      { repo: { owner: 'owner', repo: 'repo' }, issue: { number: 12 } },
      core,
      { env: { CLAUDE_TASK_COMPLETE: complete, CLAUDE_RESULT: result } },
    );
    return { issues, core };
  }

  test('moves verified delivery to review even without a PR', async () => {
    const { issues, core } = await finalize();
    expect(issues.addLabels).toHaveBeenCalledWith(expect.objectContaining({ labels: ['claude-review'] }));
    expect(issues.removeLabel).toHaveBeenCalledTimes(1);
    expect(issues.removeLabel).toHaveBeenCalledWith(expect.objectContaining({ name: 'claude-working' }));
    expect(core.setFailed).not.toHaveBeenCalled();
  });

  test.each([
    ['false', 'failure'],
    ['false', 'success'],
    ['true', 'failure'],
    ['', 'failure'],
    ['', 'cancelled'],
  ])('blocks incomplete or failed runs (%s, %s)', async (complete, result) => {
    const { issues, core } = await finalize({ complete, result });
    expect(issues.addLabels).toHaveBeenCalledWith(expect.objectContaining({ labels: ['claude-blocked'] }));
    expect(core.setFailed).toHaveBeenCalled();
  });

  test('clears queue labels on a verified no-code closure', async () => {
    const { issues } = await finalize({ state: 'closed', labels: ['bug', 'claude-working', 'claude-blocked'] });
    expect(issues.addLabels).not.toHaveBeenCalled();
    expect(issues.removeLabel.mock.calls.map(([arg]) => arg.name)).toEqual(['claude-working', 'claude-blocked']);
  });

  test.each([{ labels: ['bug'] }, { state: 'closed', result: 'failure' }])(
    'leaves unrelated or failed closed Issues alone',
    async (options) => {
      const { issues, core } = await finalize(options);
      expect(issues.addLabels).not.toHaveBeenCalled();
      expect(issues.removeLabel).not.toHaveBeenCalled();
      expect(core.setFailed).not.toHaveBeenCalled();
    },
  );

  test('isolates finalization from agent-edited files and skips untrusted/PR runs', () => {
    const job = workflow.jobs['finalize-issue'];
    expect(job).toBeDefined();
    expect(job.if).toContain('always()');
    expect(job.if).toContain("needs.claude.result != 'skipped'");
    expect(job.if).toContain('!github.event.issue.pull_request');
    expect(job.permissions).toEqual({ issues: 'write' });
    expect(job.steps).toHaveLength(1);
    expect(job.steps[0].env.CLAUDE_TASK_COMPLETE).toContain('needs.claude.outputs.task_complete');
    expect(workflow.jobs.claude.outputs.task_complete).toContain('steps.claude-result.outputs.task_complete');
    expect(workflow.concurrency.queue).toBe('max');
    expect(workflow.concurrency.group).toContain("github.event.sender.type != 'Bot'");
  });
});

describe.each(workflows)('%s starts tracked Issue requests', (file) => {
  const workflow = yaml.load(fs.readFileSync(path.join(__dirname, '..', file), 'utf8'));

  function invocation(options = {}) {
    const job = workflow.jobs.claude;
    const start = job.steps.find((step) => step.name === 'Mark tracked Issue as working');
    const labels = new Set(options.labels || ['bug', 'claude-review']);
    const changes = [];
    const apiError = Object.assign(new Error('API failure'), { status: 403 });
    const issues = {
      get: jest.fn(async () => ({
        data: { state: options.state || 'open', labels: [...labels].map((name) => ({ name })) },
      })),
      getLabel: jest.fn(async () => {}),
      createLabel: jest.fn(async () => {}),
      addLabels: jest.fn(async (args) => {
        changes.push(['add', ...args.labels]);
        args.labels.forEach((label) => labels.add(label));
      }),
      removeLabel: jest.fn(async ({ name }) => {
        changes.push(['remove', name]);
        labels.delete(name);
      }),
    };
    if (options.missingLabel) issues.getLabel.mockRejectedValueOnce({ status: 404 });
    if (options.creationRace) issues.createLabel.mockRejectedValueOnce({ status: 422 });
    if (options.failAt) issues[options.failAt].mockRejectedValueOnce(apiError);
    const github = {
      event_name: options.nonIssue ? 'pull_request_review' : 'issue_comment',
      event: {
        sender: { type: options.bot ? 'Bot' : 'User' },
        issue: options.nonIssue ? {} : { number: 12, ...(options.pr ? { pull_request: {} } : {}) },
        comment: options.nonIssue
          ? {}
          : { body: options.body || '@claude retry', author_association: options.association || 'MEMBER' },
        review: { body: '@claude review', author_association: 'MEMBER' },
        pull_request: { draft: false },
      },
    };
    const steps = {
      pr_draft: { outputs: { is_draft: options.draft ? 'true' : 'false' } },
      'claude-auth': { outputs: { available: options.auth === false ? 'false' : 'true' } },
    };
    const eligible = (expression) =>
      new Function(
        'github',
        'steps',
        'contains',
        'fromJSON',
        `return (${expression.replace(/steps\.claude-auth/g, "steps['claude-auth']")});`,
      )(github, steps, (values, value) => values.includes(value), JSON.parse);
    return {
      labels,
      changes,
      issues,
      apiError,
      async run() {
        expect(start).toBeDefined();
        if (!eligible(job.if) || !eligible(start.if)) return;
        const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
        await new AsyncFunction('github', 'context', 'core', start.with.script)(
          { rest: { issues } },
          { repo: { owner: 'owner', repo: 'repo' }, issue: { number: 12 } },
          { info() {} },
        );
      },
    };
  }

  test('adds working before removing queued or prior result labels', async () => {
    const attempt = invocation({ labels: ['bug', 'claude', 'claude-blocked', 'claude-review'] });
    await attempt.run();
    expect(attempt.changes).toEqual([
      ['add', 'claude-working'],
      ['remove', 'claude'],
      ['remove', 'claude-blocked'],
      ['remove', 'claude-review'],
    ]);
    expect([...attempt.labels]).toEqual(['bug', 'claude-working']);
  });

  test('reads the current state when a queued retry actually starts', async () => {
    const attempt = invocation();
    attempt.labels.delete('claude-review');
    attempt.labels.add('claude-blocked');
    await attempt.run();
    expect(attempt.changes).toEqual([
      ['add', 'claude-working'],
      ['remove', 'claude-blocked'],
    ]);
  });

  test.each([{ labels: ['bug'] }, { state: 'closed' }])(
    'leaves untracked or closed Issues unchanged: %j',
    async (options) => {
      const attempt = invocation(options);
      await attempt.run();
      expect(attempt.issues.get).toHaveBeenCalled();
      expect(attempt.changes).toEqual([]);
      expect(attempt.issues.getLabel).not.toHaveBeenCalled();
    },
  );

  test.each([
    { auth: false },
    { pr: true },
    { nonIssue: true },
    { draft: true },
    { bot: true },
    { association: 'NONE' },
    { body: 'thanks' },
  ])('does not touch labels for excluded invocations: %j', async (options) => {
    const attempt = invocation(options);
    await attempt.run();
    expect(attempt.issues.get).not.toHaveBeenCalled();
    expect(attempt.changes).toEqual([]);
  });

  test.each([false, true])('creates a missing working label (concurrent creator: %s)', async (creationRace) => {
    const attempt = invocation({ missingLabel: true, creationRace });
    await attempt.run();
    expect(attempt.issues.getLabel).toHaveBeenCalledTimes(creationRace ? 2 : 1);
    expect([...attempt.labels]).toEqual(['bug', 'claude-working']);
  });

  test('preserves an existing working label', async () => {
    const attempt = invocation({ labels: ['bug', 'claude-working'] });
    await attempt.run();
    expect(attempt.changes).toEqual([['add', 'claude-working']]);
  });

  test.each(['get', 'getLabel', 'createLabel', 'addLabels', 'removeLabel'])(
    'propagates %s failure so Claude cannot start',
    async (failAt) => {
      const attempt = invocation({ failAt, missingLabel: failAt === 'createLabel' });
      await expect(attempt.run()).rejects.toBe(attempt.apiError);
      if (failAt !== 'removeLabel') expect(attempt.issues.removeLabel).not.toHaveBeenCalled();
    },
  );

  test('uses fixed inline code immediately before Claude with the normal success guard', () => {
    const steps = workflow.jobs.claude.steps;
    const index = steps.findIndex((step) => step.name === 'Mark tracked Issue as working');
    expect(index).toBeGreaterThan(-1);
    expect(steps[index + 1].id).toBe('claude');
    expect(steps[index].uses).toMatch(/^actions\/github-script@[a-f0-9]{40}$/);
    expect(steps[index].if).not.toMatch(/always\(|failure\(|cancelled\(/);
    expect(steps[index + 1].if).not.toMatch(/always\(|failure\(|cancelled\(/);
    expect(workflow.concurrency.queue).toBe('max');
  });
});
