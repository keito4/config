const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const configPath = path.join(repoPath, 'commitlint.config.js');
const commitlintBin = process.platform === 'win32' ? 'commitlint.cmd' : 'commitlint';
const inheritedGitEnvKeys = ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_PREFIX'];

function cleanGitEnv(extra = {}) {
  const env = { ...process.env, ...extra };
  for (const key of inheritedGitEnvKeys) {
    delete env[key];
  }
  return env;
}

function makeGitRepo(prefix) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempDir = fs.mkdtempSync(path.join(contextDir, `${prefix}-`));
  execFileSync('git', ['init'], { cwd: tempDir, env: cleanGitEnv(), stdio: 'ignore' });
  return tempDir;
}

function stageFile(repoDir, relativePath, content) {
  const filePath = path.join(repoDir, relativePath);
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content);
  execFileSync('git', ['add', relativePath], { cwd: repoDir, env: cleanGitEnv(), stdio: 'ignore' });
}

function runCommitlint(message, cwd) {
  return execFileSync(commitlintBin, ['--config', configPath], {
    cwd,
    env: cleanGitEnv(),
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

function runReleaseTypeRuleWithStagedFiles(parsed, stagedFiles) {
  let result;
  jest.isolateModules(() => {
    jest.doMock('child_process', () => ({
      ...jest.requireActual('child_process'),
      execSync: () => `${stagedFiles.join('\n')}\n`,
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

      const result = expectCommitlintFailure('chore: update package manifest', tempDir);
      expect(result.failed).toBe(true);
      expect(result.output).toContain('release-triggering type');

      expect(() => runCommitlint('fix: update package manifest', tempDir)).not.toThrow();
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test('treats unreadable staged-file state as non-blocking', () => {
    expect(runReleaseTypeRuleWithGitFailure({ type: 'chore' })).toEqual([true]);
  });

  test('accepts Japanese commit subjects', () => {
    const tempDir = makeGitRepo('commitlint-japanese');
    try {
      expect(() => runCommitlint('docs: 日本語の説明を追加', tempDir)).not.toThrow();
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  // これら 2 件は従来 runReleaseTypeRule（実 git + process.chdir 方式）を使っていたが、
  // husky フック配下では GIT_DIR / GIT_INDEX_FILE が子プロセスへ継承され、
  // ルール内の execSync が一時リポジトリではなく実リポジトリのステージを読んで落ちる。
  // jest 環境では process.env の変更がテスト側コピーに閉じるため環境掃除でも直せず、
  // ステージ内容はこのテストの本質ではないのでモックヘルパーで固定する。
  test('treats null commit type as non-release type when release-sensitive file is staged', () => {
    // Exercises the `parsed.type || ''` branch where parsed.type is falsy.
    // '' is not in releaseTypeAllowList → should return [false, message].
    const [passes, message] = runReleaseTypeRuleWithStagedFiles({ type: null }, ['package.json']);
    expect(passes).toBe(false);
    expect(message).toContain('release-triggering type');
  });

  test('treats undefined commit type as non-release type when release-sensitive file is staged', () => {
    // Exercises the `parsed.type || ''` branch where parsed.type is undefined.
    const [passes, message] = runReleaseTypeRuleWithStagedFiles({ type: undefined }, ['package.json']);
    expect(passes).toBe(false);
    expect(message).toContain('release-triggering type');
  });

  test('getStagedFiles falls back to [] when git cannot discover a repository (catch branch)', () => {
    expect(runReleaseTypeRuleWithGitFailure({ type: 'chore' })).toEqual([true]);
  });

  test('release-type rule ignores non-sensitive staged files', () => {
    expect(runReleaseTypeRuleWithStagedFiles({ type: undefined }, ['README.md'])).toEqual([true]);
  });

  test('release-type rule rejects non-release types for sensitive staged files', () => {
    const [passed, message] = runReleaseTypeRuleWithStagedFiles({ type: 'chore' }, ['package.json']);

    expect(passed).toBe(false);
    expect(message).toContain('release-triggering type');
  });

  test('release-type rule allows release types for sensitive staged files', () => {
    expect(runReleaseTypeRuleWithStagedFiles({ type: 'fix' }, ['package-lock.json'])).toEqual([
      true,
      expect.any(String),
    ]);
  });
});
