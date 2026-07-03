'use strict';

const fs = require('fs');
const path = require('path');

const hooksDir = path.join(__dirname, '../.claude/hooks');

describe('Claude Code Hooks integrity', () => {
  const EXPECTED_HOOKS = [
    'common.py',
    'block_config_edit.py',
    'block_managed_file_edit.py',
    'block_dangerous_commands.py',
    'block_inline_secrets.py',
    'block_git_no_verify.py',
    'post_commit_adr_reminder.py',
    'post_edit_auto_lint.py',
    'post_git_push_ci.py',
    'post_pr_ai_review.py',
    'post_pr_ci_watch.py',
    'pre_exit_plan_ai_review.py',
    'pre_git_quality_gates.py',
    'stop_test_verification.py',
  ];

  describe('Hook file existence', () => {
    test.each(EXPECTED_HOOKS)('%s should exist', (hookFile) => {
      expect(fs.existsSync(path.join(hooksDir, hookFile))).toBe(true);
    });
  });

  describe('common.py — shared utility library', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'common.py'), 'utf8');
    });

    test('should define load_hook_input', () => {
      expect(content).toContain('def load_hook_input()');
    });

    test('should define parse_tool_context', () => {
      expect(content).toContain('def parse_tool_context(');
    });

    test('should define get_command', () => {
      expect(content).toContain('def get_command(');
    });

    test('should define get_git_root', () => {
      expect(content).toContain('def get_git_root()');
    });

    test('should define detect_package_manager', () => {
      expect(content).toContain('def detect_package_manager(');
    });

    test('should define build_run_command', () => {
      expect(content).toContain('def build_run_command(');
    });

    test('should support bun as a package manager', () => {
      expect(content).toContain('"bun"');
    });

    test('should support pnpm as a package manager', () => {
      expect(content).toContain('"pnpm"');
    });

    test('should support yarn as a package manager', () => {
      expect(content).toContain('"yarn"');
    });

    test('should default to npm as package manager', () => {
      expect(content).toContain('"npm"');
    });

    test('should define output formatting helpers', () => {
      expect(content).toContain('def print_header(');
      expect(content).toContain('def print_section(');
      expect(content).toContain('def print_status(');
    });

    test('should define extract_pr_url for PR detection', () => {
      expect(content).toContain('def extract_pr_url(');
    });

    test('should define CI monitoring helpers', () => {
      expect(content).toContain('def get_current_branch(');
      expect(content).toContain('def get_latest_run(');
      expect(content).toContain('def watch_ci_run(');
      expect(content).toContain('def get_pr_checks(');
    });

    test('should define AI review command helpers', () => {
      expect(content).toContain('def command_available(');
      expect(content).toContain('def run_ai_command(');
      expect(content).toContain('def run_parallel_reviews(');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });
  });

  // block_dangerous_commands.py and block_inline_secrets.py are covered in
  // test/hooks-command-safety.test.js (kept separate to respect file-length).

  describe('block_git_no_verify.py — commit hook protection', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'block_git_no_verify.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should block --no-verify flag', () => {
      expect(content).toContain('--no-verify');
    });

    test('should block HUSKY=0 env variable', () => {
      expect(content).toContain('HUSKY=0');
    });

    test('should block -n shorthand for --no-verify after git commit', () => {
      expect(content).toContain('"-n"');
    });

    test('should use shlex for safe command tokenization', () => {
      expect(content).toContain('shlex.split');
    });

    test('should exit 2 when blocked flag detected', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 for clean commands', () => {
      expect(content).toContain('sys.exit(0)');
    });

    test('should suggest sanitized alternative command', () => {
      expect(content).toContain('sanitized_cmd');
    });
  });

  describe('pre_git_quality_gates.py — CI quality enforcement', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'pre_git_quality_gates.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should detect git commit', () => {
      expect(content).toContain('is_git_commit');
    });

    test('should detect git push', () => {
      expect(content).toContain('is_git_push');
    });

    test('should check for format:check script', () => {
      expect(content).toContain('format:check');
    });

    test('should check for lint script', () => {
      expect(content).toContain('"lint"');
    });

    test('should check for test script', () => {
      expect(content).toContain('"test"');
    });

    test('should check for typecheck / tsc script', () => {
      expect(content).toContain('typecheck');
    });

    test('should check for shellcheck script', () => {
      expect(content).toContain('shellcheck');
    });

    test('should support Biome linter', () => {
      expect(content).toContain('biome');
    });

    test('should detect package manager', () => {
      expect(content).toContain('detect_package_manager');
    });

    test('should have retry logic for transient failures', () => {
      expect(content).toContain('run_with_retry');
    });

    test('should have a configurable timeout', () => {
      expect(content).toContain('DEFAULT_TIMEOUT');
    });

    test('should check for node_modules before running', () => {
      expect(content).toContain('has_node_modules');
    });

    test('should detect Biome / ESLint conflicts', () => {
      expect(content).toContain('detect_linter_conflicts');
    });

    test('should exit 2 when quality gate fails', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 when all checks pass', () => {
      expect(content).toContain('sys.exit(0)');
    });

    test('should check security credential scan script', () => {
      expect(content).toContain('security-credential-scan.sh');
    });

    test('should check code complexity script', () => {
      expect(content).toContain('code-complexity-check.sh');
    });
  });

  describe('block_config_edit.py — linter config protection', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'block_config_edit.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should define PROTECTED_BASENAMES set', () => {
      expect(content).toContain('PROTECTED_BASENAMES');
    });

    test('should protect ESLint flat config (eslint.config.mjs)', () => {
      expect(content).toContain('eslint.config.mjs');
    });

    test('should protect legacy ESLint config (.eslintrc)', () => {
      expect(content).toContain('.eslintrc');
    });

    test('should protect Biome config (biome.json)', () => {
      expect(content).toContain('biome.json');
    });

    test('should protect Prettier config (.prettierrc)', () => {
      expect(content).toContain('.prettierrc');
    });

    test('should protect TypeScript config (tsconfig.json)', () => {
      expect(content).toContain('tsconfig.json');
    });

    test('should protect ShellCheck config (.shellcheckrc)', () => {
      expect(content).toContain('.shellcheckrc');
    });

    test('should exit 2 when protected file is edited', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should exit 0 for unprotected files', () => {
      expect(content).toContain('sys.exit(0)');
    });
  });

  describe('stop_test_verification.py — session-end test runner', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'stop_test_verification.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should prevent infinite loop via STOP_HOOK_ACTIVE env var', () => {
      expect(content).toContain('STOP_HOOK_ACTIVE');
    });

    test('should check git changes before running tests', () => {
      expect(content).toContain('has_changes');
    });

    test('should look for test script in package.json', () => {
      expect(content).toContain('package.json');
    });

    test('should handle timeout gracefully', () => {
      expect(content).toContain('TimeoutExpired');
    });

    test('should send feedback when tests fail', () => {
      expect(content).toContain('hookSpecificOutput');
    });

    test('should use detect_package_manager from common', () => {
      expect(content).toContain('detect_package_manager');
    });
  });

  describe('post_commit_adr_reminder.py — architectural change detection', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'post_commit_adr_reminder.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should check for existing ADR files before reminding', () => {
      expect(content).toContain('docs/adr/');
    });

    test('should detect package.json changes as architectural signal', () => {
      expect(content).toContain('package\\.json');
    });

    test('should detect CI/CD workflow changes', () => {
      expect(content).toContain('.github/workflows/');
    });

    test('should detect Dockerfile changes', () => {
      expect(content).toContain('Dockerfile');
    });

    test('should detect docker-compose changes', () => {
      expect(content).toContain('docker-compose');
    });

    test('should detect linter/formatter config changes', () => {
      expect(content).toContain('eslint');
    });

    test('should detect TypeScript config changes', () => {
      expect(content).toContain('tsconfig');
    });

    test('should only trigger on actual git commit (not --help/--dry-run)', () => {
      expect(content).toContain('--help');
      expect(content).toContain('--dry-run');
    });

    test('should verify commit succeeded before reminding', () => {
      expect(content).toContain('exit_code');
    });

    test('should return structured JSON output for the hook framework', () => {
      expect(content).toContain('hookSpecificOutput');
    });
  });
  describe('block_managed_file_edit.py — managed sync file protection', () => {
    const { spawnSync } = require('child_process');
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'block_managed_file_edit.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should detect the Managed by keito4/config marker', () => {
      expect(content).toContain('Managed by keito4/config');
    });

    test('should skip inside the config repository itself', () => {
      expect(content).toContain('.github/sync-downstream.json');
    });

    test('should exit 2 when a managed file is edited', () => {
      expect(content).toContain('sys.exit(main())');
      expect(content).toContain('return 2');
    });

    /**
     * Run the hook as a subprocess against a temp working directory.
     * @param {string} cwd - Working directory (simulated repo root)
     * @param {string} filePath - The tool_input file path being edited
     * @returns {{ status: number, stderr: string }}
     */
    function runHook(cwd, filePath) {
      const result = spawnSync('python3', [path.join(hooksDir, 'block_managed_file_edit.py')], {
        cwd,
        encoding: 'utf8',
        input: JSON.stringify({ tool_input: { file_path: filePath } }),
        timeout: 15000,
      });
      return { status: result.status ?? 1, stderr: result.stderr ?? '' };
    }

    function makeTempRepo() {
      const contextDir = path.join(__dirname, '../.context');
      fs.mkdirSync(contextDir, { recursive: true });
      return fs.mkdtempSync(path.join(contextDir, 'managed-edit-'));
    }

    test('blocks editing a downstream file carrying the managed marker', () => {
      const repo = makeTempRepo();
      try {
        const managed = path.join(repo, '.github/workflows/label-sync.yml');
        fs.mkdirSync(path.dirname(managed), { recursive: true });
        fs.writeFileSync(managed, '# Managed by keito4/config — do not edit here.\nname: Label Sync\n');

        const result = runHook(repo, managed);
        expect(result.status).toBe(2);
        expect(result.stderr).toContain('BLOCKED');
      } finally {
        fs.rmSync(repo, { recursive: true, force: true });
      }
    });

    test('allows editing unmanaged files', () => {
      const repo = makeTempRepo();
      try {
        const normal = path.join(repo, 'src/index.js');
        fs.mkdirSync(path.dirname(normal), { recursive: true });
        fs.writeFileSync(normal, 'console.log(1);\n');

        expect(runHook(repo, normal).status).toBe(0);
      } finally {
        fs.rmSync(repo, { recursive: true, force: true });
      }
    });

    test('allows editing marked templates inside the config repository itself', () => {
      const repo = makeTempRepo();
      try {
        fs.mkdirSync(path.join(repo, '.github'), { recursive: true });
        fs.writeFileSync(path.join(repo, '.github/sync-downstream.json'), '{}');
        const template = path.join(repo, 'templates/workflows/label-sync.yml');
        fs.mkdirSync(path.dirname(template), { recursive: true });
        fs.writeFileSync(template, '# Managed by keito4/config — do not edit here.\nname: Label Sync\n');

        expect(runHook(repo, template).status).toBe(0);
      } finally {
        fs.rmSync(repo, { recursive: true, force: true });
      }
    });
  });
});
