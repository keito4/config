const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const configPath = path.join(repoPath, 'commitlint.config.js');
const commitlintBin = process.platform === 'win32' ? 'commitlint.cmd' : 'commitlint';

function makeGitRepo(prefix) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempDir = fs.mkdtempSync(path.join(contextDir, `${prefix}-`));
  execFileSync('git', ['init'], { cwd: tempDir, stdio: 'ignore' });
  return tempDir;
}

function stageFile(repoDir, relativePath, content) {
  const filePath = path.join(repoDir, relativePath);
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content);
  execFileSync('git', ['add', relativePath], { cwd: repoDir, stdio: 'ignore' });
}

function runCommitlint(message, cwd) {
  return execFileSync(commitlintBin, ['--config', configPath], {
    cwd,
    input: `${message}\n`,
    encoding: 'utf8',
    stdio: ['pipe', 'pipe', 'pipe'],
  });
}

function expectCommitlintFailure(message, cwd) {
  try {
    runCommitlint(message, cwd);
    return { failed: false, output: '' };
  } catch (error) {
    return {
      failed: true,
      output: `${error.stdout || ''}${error.stderr || ''}`,
    };
  }
}

function runReleaseTypeRule(repoDir, parsed) {
  const previousCwd = process.cwd();
  const config = require(configPath);
  const rule = config.plugins[0].rules['codex-release-type'];
  try {
    process.chdir(repoDir);
    return rule(parsed);
  } finally {
    process.chdir(previousCwd);
  }
}

function runReleaseTypeRuleWithGitFailure(parsed) {
  let result;
  jest.isolateModules(() => {
    jest.doMock('child_process', () => ({
      ...jest.requireActual('child_process'),
      execSync: () => {
        throw new Error('git unavailable');
      },
    }));
    const config = require(configPath);
    const rule = config.plugins[0].rules['codex-release-type'];
    result = rule(parsed);
    jest.dontMock('child_process');
  });
  return result;
}

describe('root commitlint configuration runtime behavior', () => {
  test('allows maintenance commits when no release-sensitive file is staged', () => {
    const tempDir = makeGitRepo('commitlint-clean');
    try {
      expect(() => runCommitlint('chore: update docs', tempDir)).not.toThrow();
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('rejects non-release commit types for staged package changes', () => {
    const tempDir = makeGitRepo('commitlint-sensitive');
    try {
      stageFile(tempDir, 'package.json', '{"name":"sample"}\n');

      const result = expectCommitlintFailure('chore: update package manifest', tempDir);
      expect(result.failed).toBe(true);
      expect(result.output).toContain('release-triggering type');
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('allows release commit types for staged package changes', () => {
    const tempDir = makeGitRepo('commitlint-release');
    try {
      stageFile(tempDir, 'package.json', '{"name":"sample"}\n');

      expect(() => runCommitlint('fix: update package manifest', tempDir)).not.toThrow();
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('evaluates the release-type plugin against actual staged files', () => {
    const tempDir = makeGitRepo('commitlint-rule-sensitive');
    try {
      stageFile(tempDir, 'package.json', '{"name":"sample"}\n');

      const [passes, message] = runReleaseTypeRule(tempDir, { type: 'chore' });
      expect(passes).toBe(false);
      expect(message).toContain('release-triggering type');

      expect(runReleaseTypeRule(tempDir, { type: 'fix' })[0]).toBe(true);
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('treats unreadable staged-file state as non-blocking', () => {
    // Create tempDir in os.tmpdir() so git auto-discovery finds no .git ancestor.
    // Using a path inside the repo (e.g. .context/) causes git to traverse up and
    // find the parent repo's staged files, making the test environment-sensitive.
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'commitlint-rule-no-git-'));
    const savedGitDir = process.env.GIT_DIR;
    // Remove any inherited GIT_DIR (e.g. set by CI/pre-commit hooks) so git must
    // auto-discover from tempDir and fail to find a repo.
    delete process.env.GIT_DIR;
    try {
      expect(runReleaseTypeRuleWithGitFailure({ type: 'chore' })).toEqual([true]);
    } finally {
      if (savedGitDir !== undefined) {
        process.env.GIT_DIR = savedGitDir;
      }
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('accepts Japanese commit subjects', () => {
    const tempDir = makeGitRepo('commitlint-japanese');
    try {
      expect(() => runCommitlint('docs: 日本語の説明を追加', tempDir)).not.toThrow();
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('getStagedFiles falls back to [] when git cannot discover a repository (catch branch)', () => {
    // Create tempDir in os.tmpdir() so git auto-discovery finds no .git ancestor.
    // getStagedFiles() → git diff throws (no repo) → catch returns [] → [true].
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'commitlint-no-repo-'));
    const savedGitDir = process.env.GIT_DIR;
    // Remove any inherited GIT_DIR (e.g. set by CI/pre-commit hooks) so git must
    // auto-discover from tempDir and fail to find a repo.
    delete process.env.GIT_DIR;
    try {
      expect(runReleaseTypeRule(tempDir, { type: 'chore' })).toEqual([true]);
    } finally {
      if (savedGitDir !== undefined) {
        process.env.GIT_DIR = savedGitDir;
      }
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });
});
