const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const configPath = path.join(repoPath, 'jest.config.js');
const baseJestConfig = require(configPath);
const jestBin = process.platform === 'win32' ? 'jest.cmd' : 'jest';

function makeTempDir(prefix) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  return fs.mkdtempSync(path.join(contextDir, `${prefix}-`));
}

function runJest(args) {
  return execFileSync(jestBin, ['--config', configPath, '--runInBand', '--reporters=default', ...args], {
    cwd: repoPath,
    encoding: 'utf8',
    env: { ...process.env, CI: '1' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

function expectJestFailure(args) {
  try {
    runJest(args);
    return { failed: false, output: '' };
  } catch (error) {
    return {
      failed: true,
      output: `${error.stdout || ''}${error.stderr || ''}`,
    };
  }
}

describe('Jest configuration runtime behavior', () => {
  test('ignores persistent worktrees under .context', () => {
    expect(baseJestConfig.testPathIgnorePatterns).toContain('<rootDir>/.context/worktrees/');
    expect(baseJestConfig.modulePathIgnorePatterns).toContain('<rootDir>/.context/worktrees/');
  });

  test('excludes ESM config modules covered by subprocess runtime tests', () => {
    expect(baseJestConfig.collectCoverageFrom).toEqual(
      expect.arrayContaining(['!eslint.config.mjs', '!eslint/complexity-rules.mjs']),
    );
  });

  test('enforces coverage thresholds when uncovered files are collected', () => {
    const tempDir = makeTempDir('jest-coverage');
    try {
      const sourceFile = path.join(tempDir, 'src', 'uncovered.js');
      const testFile = path.join(tempDir, 'test', 'coverage.test.js');
      const coverageDir = path.join(tempDir, 'coverage');
      fs.mkdirSync(path.dirname(sourceFile), { recursive: true });
      fs.mkdirSync(path.dirname(testFile), { recursive: true });
      fs.writeFileSync(sourceFile, 'module.exports = function add(a, b) { return a + b; };\n');
      fs.writeFileSync(testFile, "test('placeholder', () => { expect(true).toBe(true); });\n");

      const result = expectJestFailure([
        '--coverage',
        '--coverageReporters=text',
        `--coverageDirectory=${coverageDir}`,
        `--collectCoverageFrom=${path.relative(repoPath, sourceFile)}`,
        '--runTestsByPath',
        testFile,
      ]);

      expect(result.failed).toBe(true);
      expect(result.output).toContain('does not meet "global" threshold');
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });
});
