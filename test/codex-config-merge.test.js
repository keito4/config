'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// script/codex-config-merge.py deep-merges the repo's shared .codex/config.toml
// into the terminal-local ~/.codex/config.toml, letting the base win on shared
// keys while preserving terminal-only state (see docs/adr/0022). It normally
// runs via `uv run --script`, which auto-installs its declared `tomli_w`
// dependency. This environment has neither `uv` nor `tomli_w` installed, so
// these tests inject a minimal `tomli_w` shim onto PYTHONPATH — good enough to
// serialize the plain string/bool/nested-table values used below — letting us
// exercise the script's real control flow (script/codex-config-merge.py)
// without requiring network access or a pip install.
const SCRIPT_PATH = path.join(__dirname, '../script/codex-config-merge.py');
const CONTEXT_DIR = path.join(__dirname, '../.context');

const TOMLI_W_SHIM = `
def dumps(data):
    lines = []
    _write_table(data, [], lines)
    return "\\n".join(lines) + "\\n"


def _write_table(table, path_parts, lines):
    scalars = {k: v for k, v in table.items() if not isinstance(v, dict)}
    tables = {k: v for k, v in table.items() if isinstance(v, dict)}
    if path_parts:
        lines.append("[" + ".".join(path_parts) + "]")
    for k, v in scalars.items():
        lines.append(f"{k} = {_format(v)}")
    for k, v in tables.items():
        _write_table(v, path_parts + [k], lines)


def _format(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, str):
        escaped = v.replace("\\\\", "\\\\\\\\").replace('"', '\\\\"')
        return f'"{escaped}"'
    raise TypeError(f"unsupported type in test shim: {type(v)}")
`;

const READ_TOML_AS_JSON = `
import json
import sys
import tomllib

with open(sys.argv[1], "rb") as fh:
    print(json.dumps(tomllib.load(fh)))
`;

describe('script/codex-config-merge.py', () => {
  let stubDir;
  let readTomlScript;

  // codex-config-merge.py は tomllib を使うため Python 3.11 以上が必要。
  // macOS の /usr/bin/python3 は 3.9 で、PATH の先頭に来ることがあるため、
  // 条件を満たすものを PATH 上から選ぶ。
  function resolveModernPython() {
    for (const dir of (process.env.PATH || '').split(path.delimiter).filter(Boolean)) {
      const candidate = path.join(dir, 'python3');
      const probe = spawnSync(candidate, ['-c', 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)'], {
        encoding: 'utf8',
      });
      if (probe.status === 0) {
        return candidate;
      }
    }
    throw new Error('python3 3.11 以上が PATH 上に見つかりません (codex-config-merge.py は tomllib を使用)');
  }

  let python;

  beforeAll(() => {
    python = resolveModernPython();
    fs.mkdirSync(CONTEXT_DIR, { recursive: true });
    stubDir = fs.mkdtempSync(path.join(CONTEXT_DIR, 'codex-merge-stub-'));
    fs.writeFileSync(path.join(stubDir, 'tomli_w.py'), TOMLI_W_SHIM);
    readTomlScript = path.join(stubDir, 'read_toml_as_json.py');
    fs.writeFileSync(readTomlScript, READ_TOML_AS_JSON);
  });

  afterAll(() => {
    fs.rmSync(stubDir, { recursive: true, force: true });
  });

  function makeTempRepo() {
    return fs.mkdtempSync(path.join(CONTEXT_DIR, 'codex-merge-repo-'));
  }

  function runMerge(args) {
    const result = spawnSync(python, [SCRIPT_PATH, ...args], {
      encoding: 'utf8',
      env: { ...process.env, PYTHONPATH: stubDir },
      timeout: 15000,
    });
    return { status: result.status, stdout: result.stdout ?? '', stderr: result.stderr ?? '' };
  }

  function readToml(filePath) {
    const result = spawnSync(python, [readTomlScript, filePath], { encoding: 'utf8' });
    if (result.status !== 0) {
      throw new Error(`failed to read TOML ${filePath}: ${result.stderr}`);
    }
    return JSON.parse(result.stdout);
  }

  test('exits with usage error when arguments are missing', () => {
    const result = runMerge([]);
    expect(result.status).toBe(2);
    expect(result.stderr).toContain('Usage:');
  });

  test('exits 1 with a warning when the base file cannot be read', () => {
    const repo = makeTempRepo();
    try {
      const result = runMerge([path.join(repo, 'missing-base.toml'), path.join(repo, 'target.toml')]);
      expect(result.status).toBe(1);
      expect(result.stderr).toContain('ベースを読めません');
      expect(fs.existsSync(path.join(repo, 'target.toml'))).toBe(false);
    } finally {
      fs.rmSync(repo, { recursive: true, force: true });
    }
  });

  test('creates the target from the base when the target does not exist yet', () => {
    const repo = makeTempRepo();
    try {
      const basePath = path.join(repo, 'base.toml');
      const targetPath = path.join(repo, 'config.toml');
      fs.writeFileSync(basePath, '[a]\nvalue = "base"\n');

      const result = runMerge([basePath, targetPath]);

      expect(result.status).toBe(0);
      expect(result.stdout).toContain('マージ配備しました');
      expect(readToml(targetPath)).toEqual({ a: { value: 'base' } });
    } finally {
      fs.rmSync(repo, { recursive: true, force: true });
    }
  });

  test('deep-merges tables: base wins on shared keys, local-only state is preserved', () => {
    const repo = makeTempRepo();
    try {
      const basePath = path.join(repo, 'base.toml');
      const targetPath = path.join(repo, 'config.toml');
      fs.writeFileSync(basePath, '[a]\nvalue = "base"\n[c]\nnew = "from-base"\n');
      fs.writeFileSync(targetPath, '[a]\nvalue = "old"\nlocal_only = "keep-me"\n[b]\nlocal_table_only = "keep-too"\n');

      const result = runMerge([basePath, targetPath]);

      expect(result.status).toBe(0);
      expect(readToml(targetPath)).toEqual({
        a: { value: 'base', local_only: 'keep-me' },
        b: { local_table_only: 'keep-too' },
        c: { new: 'from-base' },
      });
    } finally {
      fs.rmSync(repo, { recursive: true, force: true });
    }
  });

  test('aborts without touching the target when it contains invalid TOML', () => {
    const repo = makeTempRepo();
    try {
      const basePath = path.join(repo, 'base.toml');
      const targetPath = path.join(repo, 'config.toml');
      fs.writeFileSync(basePath, '[a]\nvalue = "base"\n');
      const corrupted = 'this is not [ valid toml';
      fs.writeFileSync(targetPath, corrupted);

      const result = runMerge([basePath, targetPath]);

      expect(result.status).toBe(1);
      expect(result.stderr).toContain('配備先の TOML が不正です');
      expect(fs.readFileSync(targetPath, 'utf8')).toBe(corrupted);
    } finally {
      fs.rmSync(repo, { recursive: true, force: true });
    }
  });

  test('migrates a symlinked target to a real file, keeping the linked content as local state', () => {
    const repo = makeTempRepo();
    try {
      const basePath = path.join(repo, 'base.toml');
      const linkedFile = path.join(repo, 'linked-source.toml');
      const targetPath = path.join(repo, 'config.toml');
      fs.writeFileSync(basePath, '[a]\nvalue = "base"\n');
      fs.writeFileSync(linkedFile, '[a]\nlocal_only = "from-symlink"\n');
      fs.symlinkSync(linkedFile, targetPath);

      const result = runMerge([basePath, targetPath]);

      expect(result.status).toBe(0);
      expect(result.stdout).toContain('symlink を実ファイルへ移行');
      expect(fs.lstatSync(targetPath).isSymbolicLink()).toBe(false);
      expect(readToml(targetPath)).toEqual({ a: { value: 'base', local_only: 'from-symlink' } });
    } finally {
      fs.rmSync(repo, { recursive: true, force: true });
    }
  });
});
