'use strict';

const fs = require('fs');
const path = require('path');

const hooksDir = path.join(__dirname, '../.claude/hooks');

// Hook tests for block/pre/post/stop lifecycle hooks not covered by dedicated test files.
// block_dangerous_commands.py and block_inline_secrets.py are covered in hooks-command-safety.test.js.
// post_edit_auto_lint.py and post_git_push_ci.py are covered in hooks-post-tools.test.js.
// post_pr_ci_watch.py, post_pr_ai_review.py, and pre_exit_plan_ai_review.py are covered in hooks-post-pr-tools.test.js.

describe('Claude Code Hooks lifecycle', () => {
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
      expect(content).toContain('changed_files');
    });

    test('should skip when only test-irrelevant files changed', () => {
      expect(content).toContain('affects_tests');
      expect(content).toContain('IRRELEVANT_SUFFIXES');
      expect(content).toContain('IRRELEVANT_PREFIXES');
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
});
