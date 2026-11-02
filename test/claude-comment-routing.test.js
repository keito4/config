const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const context = { repo: { owner: 'Elu-co-jp', repo: 'prog-insight' }, issue: { number: 12 }, runId: 42 };

describe.each(['.github/workflows/claude.yml', 'templates/workflows/claude.yml'])(
  '%s comment routing',
  (workflowPath) => {
    const workflow = yaml.load(fs.readFileSync(path.join(__dirname, '..', workflowPath), 'utf8'));
    async function execute(name, args) {
      const step = workflow.jobs.claude.steps.find((entry) => entry.name === name);
      assert.ok(step, 'real completion verifier must exist');
      const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
      return new AsyncFunction(...Object.keys(args), step.with.script)(...Object.values(args));
    }

    const marker = 'Claude task status: complete';
    const link = '[run](https://github.com/Elu-co-jp/prog-insight/actions/runs/42)';
    const success = { type: 'result', subtype: 'success', is_error: false };
    const comment = (id, body = `${link}\n${marker}`, login = 'claude[bot]') => ({
      id,
      body,
      user: { login },
    });
    const receipt = (id, is_error = false) => ({
      type: 'assistant',
      message: {
        content: [
          { type: 'tool_use', name: 'mcp__github_comment__update_claude_comment', id: 'update' },
          {
            type: 'tool_result',
            tool_use_id: 'update',
            is_error,
            content: JSON.stringify({ content: [{ type: 'text', text: JSON.stringify({ id }) }] }),
          },
        ],
      },
    });

    async function verify(
      { reviews = [], issues = [], messages = [success], inline = true, listError, updateError } = {},
      state = {},
    ) {
      Object.assign(state, { output: {}, failures: [], reads: [], updates: [] });
      const update = (kind) => async (args) => {
        state.updates.push({ kind, ...args });
        if (kind === updateError) throw new Error(`${kind} update denied`);
      };
      await execute('Verify Claude task completion', {
        require: (name) =>
          name === 'fs' ? { existsSync: () => true, readFileSync: () => JSON.stringify(messages) } : require(name),
        context: { ...context, eventName: inline ? 'pull_request_review_comment' : 'issue_comment' },
        process: { env: { RUNNER_TEMP: '/runner/temp' } },
        github: {
          rest: {
            pulls: { listReviewComments: 'review', updateReviewComment: update('review') },
            issues: { listComments: 'issue', updateComment: update('issue') },
            markdown: {
              render: async ({ text }) => {
                assert.equal(state.output.task_complete, false);
                assert.equal(text.endsWith(marker), true);
                return { data: `<p>${marker}</p>` };
              },
            },
          },
          paginate: async (kind, args) => {
            state.reads.push(kind);
            assert.deepEqual(args, {
              ...context.repo,
              [kind === 'review' ? 'pull_number' : 'issue_number']: 12,
              per_page: 100,
            });
            if (kind === listError) throw new Error(`${kind} listing denied`);
            return kind === 'review' ? reviews : issues;
          },
        },
        core: {
          setOutput: (key, value) => {
            state.output[key] = value;
          },
          setFailed: (value) => state.failures.push(value),
          info: () => {},
        },
      });
      return state;
    }

    const unrelated = [
      comment(1, `${link.replace('/42)', '/41)')}\n${marker}`),
      comment(2, `${link}\n${marker}`, 'human'),
    ];

    test('inline reply fallback finds this run among multiple ordinary PR comments', async () => {
      const state = await verify({ reviews: unrelated, issues: [...unrelated, comment(9)] });
      assert.equal(state.output.task_complete, true);
      assert.deepEqual(state.reads, ['review', 'issue']);
      assert.deepEqual(state.updates, []);
    });

    test('current SDK receipt selects fallback comment after its run link was removed', async () => {
      const state = await verify({
        reviews: unrelated,
        issues: [...unrelated, comment(9, marker), comment(10)],
        messages: [receipt(9), success],
      });
      assert.equal(state.output.task_complete, true);
      assert.deepEqual(state.reads, ['review', 'issue']);
    });

    for (const [name, options] of [
      ['old run', { issues: [unrelated[0]] }],
      ['human receipt', { issues: [comment(9, marker, 'human')], messages: [receipt(9), success] }],
      ['wrong receipt ID', { issues: [comment(9)], messages: [receipt(99), success] }],
      ['failed receipt without run link', { issues: [comment(9, marker)], messages: [receipt(9, true), success] }],
    ]) {
      test(`fallback cannot accept ${name}`, async () => {
        const state = await verify({ reviews: unrelated, ...options });
        assert.equal(state.output.task_complete, false);
        assert.equal(state.failures.length, 1);
        assert.deepEqual(state.updates, []);
      });
    }

    for (const [name, options, kind, id] of [
      ['review', { reviews: [...unrelated, comment(7)], issues: [comment(9)] }, 'review', 7],
      ['inline fallback', { reviews: unrelated, issues: [...unrelated, comment(9)] }, 'issue', 9],
      ['ordinary issue', { inline: false, issues: [...unrelated, comment(9)] }, 'issue', 9],
    ]) {
      test(`incomplete SDK work updates the matched ${name} comment API`, async () => {
        const state = await verify({ ...options, messages: [{ ...success, is_error: true }] });
        assert.equal(state.output.task_complete, false);
        assert.equal(state.failures.length, 1);
        assert.equal(state.updates.length, 1);
        assert.equal(state.updates[0].kind, kind);
        assert.equal(state.updates[0].comment_id, id);
        assert.match(state.updates[0].body, /Completion verification: incomplete or blocked/);
        if (kind === 'review') assert.deepEqual(state.reads, ['review']);
        if (options.inline === false) assert.deepEqual(state.reads, ['issue']);
      });
    }

    test('matched review comment needs no ordinary-comment API access', async () => {
      const state = await verify({ reviews: [...unrelated, comment(7)], listError: 'issue' });
      assert.equal(state.output.task_complete, true);
      assert.deepEqual(state.reads, ['review']);
    });

    for (const kind of ['review', 'issue']) {
      test(`${kind} listing failure remains fail-closed`, async () => {
        const state = {};
        await assert.rejects(verify({ issues: [comment(9)], listError: kind }, state), /listing denied/);
        assert.equal(state.output.task_complete, false);
        assert.deepEqual(state.updates, []);
      });
    }

    test('fallback update failure cannot become task success or switch APIs', async () => {
      const state = {};
      await assert.rejects(
        verify({ issues: [comment(9)], updateError: 'issue', messages: [{ ...success, is_error: true }] }, state),
        /issue update denied/,
      );
      assert.equal(state.output.task_complete, false);
      assert.deepEqual(
        state.updates.map(({ kind }) => kind),
        ['issue'],
      );
    });
  },
);
