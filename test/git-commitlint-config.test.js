const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const configPath = path.join(repoPath, 'git', 'commitlint.config.js');
const commitlintBin = process.platform === 'win32' ? 'commitlint.cmd' : 'commitlint';

function runCommitlint(message) {
  return execFileSync(commitlintBin, ['--config', configPath], {
    cwd: repoPath,
    input: `${message}\n`,
    encoding: 'utf8',
    stdio: ['pipe', 'pipe', 'pipe'],
  });
}

function expectCommitlintFailure(message) {
  try {
    runCommitlint(message);
    return { failed: false, output: '' };
  } catch (error) {
    return {
      failed: true,
      output: `${error.stdout || ''}${error.stderr || ''}`,
    };
  }
}

describe('git/commitlint.config.js runtime behavior', () => {
  test('accepts standard Conventional Commit types', () => {
    require(configPath);
    expect(() => runCommitlint('fix: correct import behavior')).not.toThrow();
    expect(() => runCommitlint('refactor: simplify script')).not.toThrow();
  });

  test('accepts Japanese commit subjects', () => {
    expect(() => runCommitlint('docs: 日本語の説明を追加')).not.toThrow();
  });

  test('rejects messages without a Conventional Commit type', () => {
    const result = expectCommitlintFailure('update documentation');
    expect(result.failed).toBe(true);
    expect(result.output).toContain('type may not be empty');
  });

  test('rejects unknown commit types', () => {
    const result = expectCommitlintFailure('unknown: change behavior');
    expect(result.failed).toBe(true);
    expect(result.output).toContain('type must be one of');
  });
});
