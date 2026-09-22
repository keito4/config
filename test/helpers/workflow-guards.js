const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..', '..');
const inheritedGitEnvKeys = ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_PREFIX'];

function cleanGitEnv() {
  const env = { ...process.env };
  for (const key of inheritedGitEnvKeys) {
    delete env[key];
  }
  return env;
}

/**
 * repo-maintenance のワークフロー検査を、一時リポジトリに対して実行する。
 * workflows のキーがパス区切りを含めばそのまま、含まなければ .github/workflows/ に置く。
 * @param {string} flag - 実行する検査フラグ。
 * @param {Record<string, string>} workflows - 配置するワークフローの内容。
 * @returns {{status: number, output: string}} 終了コードと標準出力。
 */
function runCheck(flag, workflows) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'workflow-guards-test-'));

  try {
    for (const [name, content] of Object.entries(workflows)) {
      const target = name.includes('/') ? path.join(tempRoot, name) : path.join(tempRoot, '.github', 'workflows', name);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, content);
    }

    const scriptPath = path.join(repoPath, 'script', 'repo-maintenance.sh');
    try {
      const stdout = execFileSync('bash', [scriptPath, flag], {
        cwd: tempRoot,
        env: cleanGitEnv(),
        encoding: 'utf8',
      });
      return { status: 0, output: stdout };
    } catch (error) {
      // execFileSync が非ゼロ終了で投げた ExecException は status: number だが、
      // シグナルで kill された場合は status が null になる (signal に理由が入る)。
      // 呼び出し側は status: number を期待するため、その場合は非ゼロ値にフォールバックする。
      return { status: error.status ?? 1, output: `${error.stdout || ''}${error.stderr || ''}` };
    }
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

module.exports = { runCheck };
