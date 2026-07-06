'use strict';

const fs = require('fs');
const path = require('path');

const hooksDir = path.join(__dirname, '../.claude/hooks');

describe('Claude Code Hooks integrity', () => {
  const EXPECTED_HOOKS = [
    'common.py',
    'block_config_edit.py',
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
});
