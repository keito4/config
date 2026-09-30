const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const workflows = ['.github/workflows/claude.yml', 'templates/workflows/claude.yml'];
const complete = '- [x] Result posted\n<!-- claude-task-status: complete -->';

async function verify(workflowPath, messages, body = complete, options = {}) {
  const workflow = yaml.load(fs.readFileSync(path.join(__dirname, '..', workflowPath), 'utf8'));
  const step = workflow.jobs.claude.steps.find((entry) => entry.id === 'claude-result');
  expect(step).toBeDefined();
  expect(step.if).toContain('!cancelled()');
  const outputs = {};
  const core = {
    setOutput: (key, value) => (outputs[key] = value),
    info: jest.fn(),
    warning: jest.fn(),
    setFailed: jest.fn(),
  };
  const comment = {
    id: 7,
    user: { login: options.login || 'claude[bot]' },
    body: `**Claude finished**\n[View job](https://github.com/owner/repo/actions/runs/42)\n${body}`,
  };
  const github = {
    paginate: jest
      .fn()
      .mockResolvedValue(
        options.olderBody
          ? [{ ...comment, id: 6, body: comment.body.replace(body, options.olderBody) }, comment]
          : [comment],
      ),
    rest: {
      issues: { listComments: jest.fn(), updateComment: jest.fn() },
      pulls: { listReviewComments: jest.fn(), updateReviewComment: jest.fn() },
    },
  };
  const context = {
    repo: { owner: 'owner', repo: 'repo' },
    runId: 42,
    issue: { number: 12 },
    eventName: options.eventName || 'issue_comment',
  };
  const read = { existsSync: () => messages !== null, readFileSync: () => JSON.stringify(messages) };
  const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
  await new AsyncFunction('require', 'core', 'github', 'context', 'process', step.with.script)(
    (name) => (name === 'fs' ? read : require(name)),
    core,
    github,
    context,
    { env: { RUNNER_TEMP: '/runner/temp', CLAUDE_EXECUTION_FILE: '/runner/temp/claude-execution-output.json' } },
  );
  return { outputs, core, github };
}

describe.each(workflows)('%s validates delivered work', (workflowPath) => {
  const result = { type: 'result', subtype: 'success', is_error: false, permission_denials: [] };

  test('accepts a posted final result even after a recovered permission denial', async () => {
    const { outputs, core } = await verify(workflowPath, [
      { ...result, permission_denials: [{ tool_name: 'Bash', tool_input: { command: 'make test SECRET_VALUE' } }] },
    ]);
    expect(outputs.task_complete).toBe(true);
    expect(core.setFailed).not.toHaveBeenCalled();
    expect(core.info.mock.calls.flat().join(' ')).toContain('Bash:make');
    expect(core.info.mock.calls.flat().join(' ')).not.toContain('SECRET_VALUE');
  });

  test.each([
    ['progress only', '- [ ] Post findings'],
    ['checked boxes but no final result', '- [x] Post findings\nStill working'],
    ['a quoted/example completion marker', 'The example is <!-- claude-task-status: complete -->'],
    ['unfinished tasks under a complete marker', `- [ ] Run tests\n${complete}`],
    ['explicitly blocked', '<!-- claude-task-status: blocked -->\nNeeds authentication'],
  ])('rejects %s', async (_label, body) => {
    const { outputs, core, github } = await verify(workflowPath, [result], body);
    expect(outputs.task_complete).toBe(false);
    expect(core.setFailed).toHaveBeenCalled();
    expect(github.rest.issues.updateComment.mock.calls[0][0].body).not.toContain('**Claude finished**');
  });

  test('checks the latest attempt instead of a prior success with the same run ID', async () => {
    const { outputs } = await verify(workflowPath, [result], '- [ ] Still working', { olderBody: complete });
    expect(outputs.task_complete).toBe(false);
  });

  test('does not accept a human comment that copies the completion marker', async () => {
    const { outputs } = await verify(workflowPath, [result], complete, { login: 'someone' });
    expect(outputs.task_complete).toBe(false);
  });

  test('updates the correct review-comment API for an inline request', async () => {
    const { outputs, github } = await verify(workflowPath, [result], '- [ ] Still working', {
      eventName: 'pull_request_review_comment',
    });
    expect(outputs.task_complete).toBe(false);
    expect(github.rest.pulls.updateReviewComment).toHaveBeenCalled();
    expect(github.rest.issues.updateComment).not.toHaveBeenCalled();
  });

  test('rejects is_error:true even with a complete comment', async () => {
    const { outputs, core } = await verify(workflowPath, [{ ...result, is_error: true, result: 'SECRET_VALUE' }]);
    expect(outputs.task_complete).toBe(false);
    expect(core.info.mock.calls.flat().join(' ')).not.toContain('SECRET_VALUE');
  });

  test('fails closed when no execution result was saved', async () => {
    const { outputs, core } = await verify(workflowPath, null);
    expect(outputs.task_complete).toBe(false);
    expect(core.setFailed).toHaveBeenCalled();
  });

  test('creates a draft for a pushed branch when completion failed', () => {
    const workflow = yaml.load(fs.readFileSync(path.join(__dirname, '..', workflowPath), 'utf8'));
    const step = workflow.jobs.claude.steps.find((entry) => entry.name === 'Create pull request from Claude branch');
    expect(step.if).toContain('!cancelled()');
    expect(step.env.CLAUDE_TASK_COMPLETE).toContain('steps.claude-result.outputs.task_complete');
    expect(step.run).toContain('PR_ARGS=(--draft)');
    expect(step.run).toContain('"${PR_ARGS[@]}"');
    expect(step.run).toContain('ISSUE_ACTION="Refs"');
  });
});
