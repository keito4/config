const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const configPath = path.join(repoPath, 'eslint.config.mjs');
const eslintBin = process.platform === 'win32' ? 'eslint.cmd' : 'eslint';

function makeTempDir(prefix) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  return fs.mkdtempSync(path.join(contextDir, `${prefix}-`));
}

function runEslint(filePath, extraArgs = []) {
  return execFileSync(eslintBin, ['--config', configPath, '--no-ignore', ...extraArgs, filePath], {
    cwd: repoPath,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

function expectEslintFailure(filePath, extraArgs = []) {
  try {
    runEslint(filePath, extraArgs);
    return { failed: false, output: '' };
  } catch (error) {
    return {
      failed: true,
      output: `${error.stdout || ''}${error.stderr || ''}`,
    };
  }
}

describe('ESLint configuration runtime behavior', () => {
  test('ignores shared context artifacts during full repository lint', () => {
    const config = fs.readFileSync(configPath, 'utf8');

    expect(config).toContain("'.context/'");
  });

  test('allows console usage and ignored underscore arguments', () => {
    const tempDir = makeTempDir('eslint-valid');
    try {
      const filePath = path.join(tempDir, 'valid.js');
      fs.writeFileSync(filePath, "function main(_ignored) { console.log('ok'); }\nmain();\n");

      expect(() => runEslint(filePath)).not.toThrow();
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('fails on unused variables', () => {
    const tempDir = makeTempDir('eslint-unused');
    try {
      const filePath = path.join(tempDir, 'unused.js');
      fs.writeFileSync(filePath, 'const unused = 1;\n');

      const result = expectEslintFailure(filePath);
      expect(result.failed).toBe(true);
      expect(result.output).toContain('no-unused-vars');
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('can promote complexity warnings to failures in CI mode', () => {
    const tempDir = makeTempDir('eslint-complexity');
    try {
      const filePath = path.join(tempDir, 'complex.js');
      const branches = Array.from({ length: 18 }, (_, index) => `  if (value === ${index}) return ${index};`).join(
        '\n',
      );
      fs.writeFileSync(filePath, `function branch(value) {\n${branches}\n  return value;\n}\nbranch(1);\n`);

      const result = expectEslintFailure(filePath, ['--max-warnings=0']);
      expect(result.failed).toBe(true);
      expect(result.output).toContain('complexity');
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });
});
