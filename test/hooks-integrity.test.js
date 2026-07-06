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
  //
  // block_git_no_verify.py, pre_git_quality_gates.py, block_config_edit.py,
  // stop_test_verification.py, and post_commit_adr_reminder.py are covered in
  // test/hooks-lifecycle.test.js (kept separate to respect file-length).

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
