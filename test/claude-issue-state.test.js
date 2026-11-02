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
