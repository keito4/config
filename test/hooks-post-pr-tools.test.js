'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const hooksDir = path.join(__dirname, '../.claude/hooks');
const python = spawnSync('which', ['python3'], { encoding: 'utf8' }).stdout.trim();

let sandbox;
let binDir;
let homeDir;

function fakeCommand(name, stdout, code = 0) {
  // printf is a shell builtin, so the script works with PATH limited to binDir.
  const quoted = `'${stdout.replace(/'/g, "'\\''")}'`;
  fs.writeFileSync(path.join(binDir, name), `#!/bin/sh\nprintf '%s\\n' ${quoted}\nexit ${code}\n`, { mode: 0o755 });
}

function runHook(script, input) {
  // PATH holds only the fake bin dir so real codex/gemini/gh are never reached.
  return spawnSync(python, [path.join(hooksDir, script)], {
    input: JSON.stringify(input),
    encoding: 'utf8',
    cwd: hooksDir,
    env: { PATH: binDir, HOME: homeDir },
    timeout: 20000,
  });
}

function writePlan() {
  const plans = path.join(homeDir, '.claude', 'plans');
  fs.mkdirSync(plans, { recursive: true });
  fs.writeFileSync(path.join(plans, 'plan.md'), '# plan\n');
}

const bashPostInput = (command, stdout = '') => ({
  tool_name: 'Bash',
  tool_input: { command },
  tool_response: { stdout, stderr: '' },
});
const PR_OUTPUT = 'https://github.com/o/r/pull/7';

beforeEach(() => {
  sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'hooks-pr-'));
  binDir = path.join(sandbox, 'bin');
  homeDir = path.join(sandbox, 'home');
  fs.mkdirSync(binDir);
  fs.mkdirSync(homeDir);
});

afterEach(() => fs.rmSync(sandbox, { recursive: true, force: true }));

describe('post_pr_ci_watch.py', () => {
  test.each([
    ['unrelated commands', bashPostInput('git status', PR_OUTPUT)],
    ['help invocations', bashPostInput('gh pr create --help', PR_OUTPUT)],
    ['output without a PR URL', bashPostInput('gh pr create', 'error')],
    ['non-Bash tools', { tool_name: 'Edit', tool_input: { command: 'gh pr create' } }],
  ])('does nothing for %s', (_, input) => {
    const r = runHook('post_pr_ci_watch.py', input);
    expect(r.status).toBe(0);
    expect(r.stderr).toBe('');
  });

  test('reports failing checks without blocking', () => {
    fakeCommand('gh', '[{"name":"lint","bucket":"fail"}]', 1);
    const r = runHook('post_pr_ci_watch.py', bashPostInput('gh pr create', PR_OUTPUT));
    expect(r.status).toBe(0);
    expect(r.stderr).toContain('- lint');
    expect(r.stderr).toContain('このブランチで修正');
  });

  test('reports success when all checks pass', () => {
    fakeCommand('gh', '[{"name":"lint","bucket":"pass"}]');
    const r = runHook('post_pr_ci_watch.py', bashPostInput('gh pr create', PR_OUTPUT));
    expect(r.status).toBe(0);
    expect(r.stderr).toContain('全CIチェック成功');
  });
});

describe('post_pr_ai_review.py', () => {
  test('ignores commands other than gh pr create', () => {
    const r = runHook('post_pr_ai_review.py', bashPostInput('git status', PR_OUTPUT));
    expect(r.status).toBe(0);
    expect(r.stderr).toBe('');
  });

  test('skips without blocking when neither codex nor gemini is installed', () => {
    const r = runHook('post_pr_ai_review.py', bashPostInput('gh pr create', PR_OUTPUT));
    expect(r.status).toBe(0);
    expect(r.stderr).toContain('スキップ');
  });
});

describe('pre_exit_plan_ai_review.py', () => {
  const exitPlan = { tool_name: 'ExitPlanMode', tool_input: {} };

  test('ignores tools other than ExitPlanMode', () => {
    fakeCommand('codex', 'plan needs revision');
    writePlan();
    const r = runHook('pre_exit_plan_ai_review.py', { tool_name: 'Bash', tool_input: {} });
    expect(r.status).toBe(0);
    expect(r.stderr).toBe('');
  });

  test('skips when no AI tool is installed', () => {
    writePlan();
    const r = runHook('pre_exit_plan_ai_review.py', exitPlan);
    expect(r.status).toBe(0);
    expect(r.stderr).toContain('スキップ');
  });

  test('skips when no plan file exists', () => {
    fakeCommand('codex', 'plan needs revision');
    const r = runHook('pre_exit_plan_ai_review.py', exitPlan);
    expect(r.status).toBe(0);
    expect(r.stderr).toContain('プランファイルが見つかりません');
  });

  test('blocks with exit 2 when a reviewer says the plan needs revision', () => {
    fakeCommand('codex', 'Verdict: plan needs revision');
    writePlan();
    expect(runHook('pre_exit_plan_ai_review.py', exitPlan).status).toBe(2);
  });

  test('allows when the reviewer says the plan is ready', () => {
    fakeCommand('gemini', 'Verdict: plan is ready');
    writePlan();
    const r = runHook('pre_exit_plan_ai_review.py', exitPlan);
    expect(r.status).toBe(0);
    expect(r.stderr).toContain('問題なし');
  });
});
