const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const workflows = ['.github/workflows/claude.yml', 'templates/workflows/claude.yml'];
const complete = '- [x] Result posted\nClaude task status: complete';
// GitHub POST /markdown, mode:gfm, recorded 2026-11-02. No test-side Markdown parser.
const rendered = fs
  .readFileSync(path.join(__dirname, 'fixtures/claude-markdown.jsonl'), 'utf8')
  .trim()
  .split('\n')
  .map(JSON.parse);
const renderedByName = Object.fromEntries(rendered.map((fixture) => [fixture.name, fixture.html]));

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
    body: options.noRunLink
      ? body
      : `**Claude finished**\n[View job](https://github.com/owner/repo/actions/runs/42)\n${body}`,
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
      markdown: {
        render: jest.fn(async (args) => {
          expect(args).toEqual({ text: comment.body, mode: 'gfm', context: 'owner/repo' });
          if (options.renderError) throw new Error('render denied');
          return { data: Object.hasOwn(options, 'html') ? options.html : renderedByName.complete };
        }),
      },
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
    ['progress only', '- [ ] Post findings', renderedByName.bullet],
    ['checked boxes but no final result', '- [x] Post findings\nStill working'],
    ['a quoted/example completion marker', 'The example is Claude task status: complete'],
    ['unfinished tasks under a complete marker', `- [ ] Run tests\n${complete}`, renderedByName.bullet],
    ['explicitly blocked', 'Claude task status: blocked\nNeeds authentication'],
    ...[
      ['plus', '+ [ ] Validate'],
      ['ordered', '1. [ ] Validate'],
      ['paren', '1) [ ] Validate'],
      ['spaces', '-  [ ] Validate'],
      ['tabs', '*\t[\t] Validate'],
      ['nbsp', '  2. [\u00a0] Validate'],
    ].map(([name, item]) => [item, `${item}\n${complete}`, renderedByName[name]]),
  ])('rejects %s', async (_label, body, html = renderedByName.complete) => {
    const { outputs, core, github } = await verify(workflowPath, [result], body, { html });
    expect(outputs.task_complete).toBe(false);
    expect(core.setFailed).toHaveBeenCalled();
    expect(github.rest.issues.updateComment.mock.calls[0][0].body).not.toContain('**Claude finished**');
  });

  test.each(rendered)('uses native GFM structure: $name', async (fixture) => {
    expect((await verify(workflowPath, [result], fixture.body, { html: fixture.html })).outputs.task_complete).toBe(
      fixture.complete,
    );
  });

  test('Markdown render failures and invalid responses fail closed', async () => {
    await expect(verify(workflowPath, [result], complete, { renderError: true })).rejects.toThrow('render denied');
    for (const html of ['', null, {}, 'not HTML']) {
      await expect(verify(workflowPath, [result], complete, { html })).rejects.toThrow(/render/i);
    }
  });

  test('keeps the visible status after the upstream HTML sanitizer', async () => {
    const sanitized = `${complete}\n<!-- invisible -->`.replace(/<!--[\s\S]*?-->/g, '');
    expect((await verify(workflowPath, [result], sanitized)).outputs.task_complete).toBe(true);
  });

  test('identifies the updated comment from its successful MCP receipt without a run link', async () => {
    const messages = [
      {
        type: 'assistant',
        message: { content: [{ type: 'tool_use', id: 'call-1', name: 'mcp__github_comment__update_claude_comment' }] },
      },
      {
        type: 'user',
        message: {
          content: [
            {
              type: 'tool_result',
              tool_use_id: 'call-1',
              content: [{ type: 'text', text: JSON.stringify({ id: 7 }) }],
            },
          ],
        },
      },
      result,
    ];
    expect((await verify(workflowPath, messages, complete, { noRunLink: true })).outputs.task_complete).toBe(true);
    messages[1].message.content[0].is_error = true;
    expect((await verify(workflowPath, messages, complete, { noRunLink: true })).outputs.task_complete).toBe(false);
  });

  test('checks the latest attempt instead of a prior success with the same run ID', async () => {
    const { outputs } = await verify(workflowPath, [result], '- [ ] Still working', {
      olderBody: complete,
      html: renderedByName.bullet,
    });
    expect(outputs.task_complete).toBe(false);
  });

  test('does not accept a human comment that copies the completion marker', async () => {
    const { outputs } = await verify(workflowPath, [result], complete, { login: 'someone' });
    expect(outputs.task_complete).toBe(false);
  });

  test('updates the correct review-comment API for an inline request', async () => {
    const { outputs, github } = await verify(workflowPath, [result], '- [ ] Still working', {
      eventName: 'pull_request_review_comment',
      html: renderedByName.bullet,
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
