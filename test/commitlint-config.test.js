const fs = require('fs');
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
    const contextDir = path.join(repoPath, '.context');
    fs.mkdirSync(contextDir, { recursive: true });
    const tempDir = fs.mkdtempSync(path.join(contextDir, 'commitlint-rule-no-git-'));
    try {
      expect(runReleaseTypeRule(tempDir, { type: 'chore' })).toEqual([true]);
    } finally {
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
    // The existing "unreadable staged-file state" test runs inside .context/ which is
    // still part of the git repo, so git succeeds and the catch block at line 19 is
    // never exercised. This test sets GIT_CEILING_DIRECTORIES to .context/ so that git
    // stops searching before it can find the parent .git directory, forcing the
    // execSync call to throw and triggering the catch → return [].
    const contextDir = path.join(repoPath, '.context');
    fs.mkdirSync(contextDir, { recursive: true });
    const tempDir = fs.mkdtempSync(path.join(contextDir, 'commitlint-ceiling-'));
    const savedCeiling = process.env.GIT_CEILING_DIRECTORIES;
    process.env.GIT_CEILING_DIRECTORIES = contextDir;
    try {
      // getStagedFiles() → git diff throws (no repo visible) → catch returns []
      // → touched is empty → releaseTypeRule returns [true] (non-blocking)
      expect(runReleaseTypeRule(tempDir, { type: 'chore' })).toEqual([true]);
    } finally {
      if (savedCeiling === undefined) {
        delete process.env.GIT_CEILING_DIRECTORIES;
      } else {
        process.env.GIT_CEILING_DIRECTORIES = savedCeiling;
      }
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });
});
