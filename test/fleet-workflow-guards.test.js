const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const repoPath = path.resolve(__dirname, '..');
const inheritedGitEnvKeys = ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_PREFIX'];

function cleanGitEnv(extra = {}) {
  const env = { ...process.env, ...extra };
  for (const key of inheritedGitEnvKeys) {
    delete env[key];
  }
  return env;
}

/**
 * gh のスタブを作る。repo list は discovered を返し、repo clone は fixtures を配置する。
 * @param {object} options - スタブの内容。
 * @param {string[]} options.discovered - `gh repo list` が返すリポジトリ名。
 * @param {Record<string, Record<string, string>>} options.workflows - リポジトリ名ごとの配置内容。
 * @returns {string} gh スタブのシェルスクリプト。
 */
function buildGhStub({ discovered = [], workflows = {}, discoveryFails = false }) {
  const lines = ['#!/usr/bin/env bash', 'if [ "$1" = "repo" ] && [ "$2" = "list" ]; then'];
  if (discoveryFails) {
    // 失効した PAT で gh が返す形。stdout は空、stderr にエラー、終了ステータスは非ゼロ。
    lines.push('  echo "gh: Bad credentials (HTTP 401)" >&2', '  exit 1');
  } else {
    for (const name of discovered) {
      lines.push(`  echo '${name}'`);
    }
    lines.push('  exit 0');
  }
  lines.push('fi', 'if [ "$1" = "repo" ] && [ "$2" = "clone" ]; then');
  // gh repo clone <owner/name> <dest> -- <flags...> なので $3=owner/name, $4=dest
  // 既知のリポジトリのときだけ dest を作る。未知のものは「clone は成功したが
  // チェックアウトが無い」状況を再現する。
  lines.push('  name="${3##*/}"', '  dest="$4"');
  for (const [name, files] of Object.entries(workflows)) {
    lines.push(`  if [ "$name" = "${name}" ]; then`);
    lines.push('    mkdir -p "$dest"');
    for (const [file, content] of Object.entries(files)) {
      lines.push(`    mkdir -p "$dest/$(dirname "${file}")"`);
      lines.push(`    cat > "$dest/${file}" <<'WORKFLOW_EOF'\n${content}\nWORKFLOW_EOF`);
    }
    lines.push('  fi');
  }
  lines.push('  exit 0', 'fi', 'exit 1', '');
  return lines.join('\n');
}

function runFleet(args, { discovered = [], workflows = {}, discoveryFails = false, env = {} } = {}) {
  const contextDir = path.join(repoPath, '.context');
  fs.mkdirSync(contextDir, { recursive: true });
  const tempRoot = fs.mkdtempSync(path.join(contextDir, 'fleet-guards-test-'));

  try {
    const binDir = path.join(tempRoot, 'bin');
    fs.mkdirSync(binDir, { recursive: true });
    const ghPath = path.join(binDir, 'gh');
    fs.writeFileSync(ghPath, buildGhStub({ discovered, workflows, discoveryFails }));
    fs.chmodSync(ghPath, 0o755);

    const scriptPath = path.join(repoPath, 'script', 'fleet-workflow-guards.sh');
    try {
      const stdout = execFileSync('bash', [scriptPath, ...args], {
        cwd: repoPath,
        env: cleanGitEnv({
          ...env,
          PATH: `${binDir}:${process.env.PATH}`,
          FLEET_WORK_DIR: path.join(tempRoot, 'work'),
        }),
        encoding: 'utf8',
      });
      return { status: 0, output: stdout };
    } catch (error) {
      return { status: error.status, output: `${error.stdout || ''}${error.stderr || ''}` };
    }
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

const CLEAN_WORKFLOW = [
  'name: CI',
  'jobs:',
  '  build:',
  '    steps:',
  '      - uses: actions/checkout@abc123 # v7.0.1',
  '',
].join('\n');

// keito4/config PR #1066 と同じ欠陥。checkout せずに gh label create を呼ぶ。
const GH_CONTEXT_VIOLATION = [
  'name: Dependabot Auto-merge',
  'jobs:',
  '  dependabot-auto:',
  '    steps:',
  '      - run: gh label create "dependabot-minor" --force',
  '',
].join('\n');

// check_artifact_retention は output::warning ではなく素の "file: message" を出す。
// ⚠ 行だけを拾う実装だと、非ゼロ終了しているのに違反が消えて clean と報告される。
const ARTIFACT_RETENTION_VIOLATION = [
  'name: CI',
  'jobs:',
  '  build:',
  '    steps:',
  '      - uses: actions/checkout@abc123 # v7.0.1',
  '      - uses: actions/upload-artifact@abc123 # v4',
  '        with:',
  '          name: coverage',
  '',
].join('\n');

describe('script/fleet-workflow-guards.sh', () => {
  test('detects a guard whose diagnostics are not warning-formatted', () => {
    const result = runFleet(['--repos', 'alpha'], {
      workflows: { alpha: { '.github/workflows/ci.yml': ARTIFACT_RETENTION_VIOLATION } },
    });

    expect(result.status).not.toBe(0);
    expect(result.output).not.toContain('No workflow guard violations');
    expect(result.output).toContain('alpha');
  });

  test('rejects a repository name that would escape the work directory', () => {
    const result = runFleet(['--repos', '../escape'], { workflows: {} });

    expect(result.status).not.toBe(0);
    expect(result.output).toMatch(/invalid|不正/i);
  });

  test.each([['0'], ['-5'], ['abc']])('rejects an invalid --days value (%s)', (days) => {
    const result = runFleet(['--days', days, '--repos', 'alpha'], {
      workflows: { alpha: { '.github/workflows/ci.yml': CLEAN_WORKFLOW } },
    });

    expect(result.status).not.toBe(0);
    expect(result.output).toMatch(/invalid|不正/i);
  });

  test('reports no violations when every repository is clean', () => {
    const result = runFleet(['--repos', 'alpha bravo'], {
      workflows: {
        alpha: { '.github/workflows/ci.yml': CLEAN_WORKFLOW },
        bravo: { '.github/workflows/ci.yml': CLEAN_WORKFLOW },
      },
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('alpha');
    expect(result.output).toContain('bravo');
    expect(result.output).toContain('No workflow guard violations');
  });

  test('fails and names the offending repository and workflow', () => {
    const result = runFleet(['--repos', 'alpha bravo'], {
      workflows: {
        alpha: { '.github/workflows/ci.yml': CLEAN_WORKFLOW },
        bravo: { '.github/workflows/dependabot-auto-merge.yml': GH_CONTEXT_VIOLATION },
      },
    });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('bravo');
    expect(result.output).toContain('dependabot-auto-merge.yml');
  });

  // 1 リポジトリの違反で走査を打ち切ると、残りの実態が分からないまま直すことになる。
  test('scans every repository even after one fails', () => {
    const result = runFleet(['--repos', 'alpha bravo charlie'], {
      workflows: {
        alpha: { '.github/workflows/dependabot-auto-merge.yml': GH_CONTEXT_VIOLATION },
        bravo: { '.github/workflows/ci.yml': CLEAN_WORKFLOW },
        charlie: { '.github/workflows/dependabot-auto-merge.yml': GH_CONTEXT_VIOLATION },
      },
    });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('alpha');
    expect(result.output).toContain('bravo');
    expect(result.output).toContain('charlie');
  });

  // 失効した PAT では gh repo list が 401 で 0 行を返す。終了ステータスを見ないと
  // 「走査対象なし」と区別が付かず、何も検査していないのに緑で終わる。
  test('fails loudly when repository discovery cannot reach the GitHub API', () => {
    const result = runFleet([], { discoveryFails: true });

    expect(result.status).not.toBe(0);
    expect(result.output).not.toContain('No workflow guard violations');
    expect(result.output).toMatch(/discover/i);
  });

  test('discovers repositories from the owner when --repos is omitted', () => {
    const result = runFleet([], {
      discovered: ['alpha', 'bravo'],
      workflows: {
        alpha: { '.github/workflows/ci.yml': CLEAN_WORKFLOW },
        bravo: { '.github/workflows/ci.yml': CLEAN_WORKFLOW },
      },
    });

    expect(result.status).toBe(0);
    expect(result.output).toContain('alpha');
    expect(result.output).toContain('bravo');
  });

  // config が配る templates/workflows/ も検査対象。下流に配られた欠陥を取りこぼさない。
  test('checks distributed templates in the scanned repository', () => {
    const result = runFleet(['--repos', 'alpha'], {
      workflows: {
        alpha: { 'templates/workflows/claude-health-check.yml': GH_CONTEXT_VIOLATION },
      },
    });

    expect(result.status).not.toBe(0);
    expect(result.output).toContain('claude-health-check.yml');
  });

  test('writes a markdown summary when GITHUB_STEP_SUMMARY is set', () => {
    const contextDir = path.join(repoPath, '.context');
    fs.mkdirSync(contextDir, { recursive: true });
    const summaryPath = path.join(contextDir, `fleet-summary-${process.pid}.md`);

    try {
      runFleet(['--repos', 'alpha'], {
        workflows: { alpha: { '.github/workflows/ci.yml': CLEAN_WORKFLOW } },
        env: { GITHUB_STEP_SUMMARY: summaryPath },
      });

      const summary = fs.readFileSync(summaryPath, 'utf8');
      expect(summary).toContain('Workflow guard');
      expect(summary).toContain('alpha');
    } finally {
      fs.rmSync(summaryPath, { force: true });
    }
  });

  // clone が成功したように見えてチェックアウトが無い場合、黙って clean と報告しては
  // いけない。走査できなかったことが分かる形で残す必要がある。
  test('does not report clean when the checkout is missing', () => {
    const result = runFleet(['--repos', 'ghost'], { workflows: {} });

    expect(result.output).not.toContain('No workflow guard violations');
    expect(result.output).toContain('ghost');
  });

  test('treats a repository without workflows as clean instead of erroring', () => {
    const result = runFleet(['--repos', 'empty'], { workflows: { empty: {} } });

    expect(result.status).toBe(0);
    expect(result.output).toContain('empty');
  });
});

describe('Fleet workflow guards CI contract', () => {
  function readFile(relativePath) {
    return fs.readFileSync(path.join(repoPath, relativePath), 'utf8');
  }

  test('the workflow delegates to the executable script', () => {
    const workflow = readFile('.github/workflows/fleet-workflow-guards.yml');

    expect(workflow).toContain('script/fleet-workflow-guards.sh');
    expect(workflow).toContain('workflow_dispatch:');
    expect(workflow).toContain('schedule:');
    // 他リポジトリを読むため PAT が要る。GITHUB_TOKEN は自リポジトリしか見えない。
    expect(workflow).toContain('secrets.CLAUDE_PAT');
    // 走査は読み取りのみ。他リポジトリへは書き込まない。
    expect(workflow).not.toContain('gh issue create');
    expect(workflow).not.toContain('gh pr create');
  });
});
