const fs = require('fs');
const path = require('path');
const { execFileSync, spawnSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const gitEnv = { ...process.env };
for (const key of execFileSync('git', ['rev-parse', '--local-env-vars'], { encoding: 'utf8' }).trim().split('\n')) {
  delete gitEnv[key];
}

test('fixture suites preserve a linked worktree parent when Git paths are inherited', () => {
  const context = path.join(repoPath, '.context');
  fs.mkdirSync(context, { recursive: true });
  const dir = fs.mkdtempSync(path.join(context, 'git-env-isolation-'));
  const parent = path.join(dir, 'parent');
  const linked = path.join(dir, 'linked');
  fs.mkdirSync(parent);
  const git = (...args) => execFileSync('git', args, { cwd: parent, env: gitEnv, encoding: 'utf8' }).trim();

  try {
    git('init', '-b', 'main');
    git('config', 'user.name', 'Fixture');
    git('config', 'user.email', 'fixture@example.invalid');
    fs.writeFileSync(path.join(parent, 'tracked'), 'unchanged\n');
    git('add', 'tracked');
    git('commit', '-m', 'chore: fixture');
    git('worktree', 'add', '-b', 'linked', linked);
    const common = path.join(parent, '.git');
    const config = fs.readFileSync(path.join(common, 'config'), 'utf8');
    const refs = git('show-ref');
    const index = fs.readFileSync(path.join(common, 'index'));
    const result = spawnSync(
      process.execPath,
      [
        require.resolve('jest/bin/jest'),
        '--runInBand',
        '--no-cache',
        '--runTestsByPath',
        'test/repo-maintenance-actions-settings.test.js',
        'test/repo-maintenance-workflow-guards.test.js',
        'test/fleet-workflow-guards.test.js',
        'test/repo-maintenance-contract.test.js',
        'test/commitlint-config.test.js',
      ],
      {
        cwd: repoPath,
        env: {
          ...gitEnv,
          PATH: `${path.join(repoPath, 'node_modules', '.bin')}${path.delimiter}${gitEnv.PATH}`,
          GIT_DIR: path.join(common, 'worktrees', 'linked'),
          GIT_COMMON_DIR: common,
          GIT_WORK_TREE: linked,
          GIT_INDEX_FILE: path.join(common, 'worktrees', 'linked', 'index'),
          GIT_OBJECT_DIRECTORY: path.join(common, 'objects'),
          JEST_JUNIT_OUTPUT_DIR: dir,
        },
        encoding: 'utf8',
        timeout: 60000,
        maxBuffer: 10 * 1024 * 1024,
      },
    );
    expect(fs.readFileSync(path.join(common, 'config'), 'utf8')).toBe(config);
    expect(fs.readFileSync(path.join(common, 'index'))).toEqual(index);
    expect(git('show-ref')).toBe(refs);
    expect(git('status', '--porcelain')).toBe('');
    expect({
      status: result.status,
      error: result.error?.message,
      output: result.status === 0 ? '' : result.stderr.slice(-3000),
    }).toEqual({ status: 0, error: undefined, output: '' });
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}, 70000);
