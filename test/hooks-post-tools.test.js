'use strict';

const fs = require('fs');
const path = require('path');

const hooksDir = path.join(__dirname, '../.claude/hooks');
const commonContent = fs.readFileSync(path.join(hooksDir, 'common.py'), 'utf8');

describe('Post-tool hooks — content and structure', () => {
  // ──────────────────────────────────────────────────────────────
  // post_edit_auto_lint.py
  // ──────────────────────────────────────────────────────────────
  describe('post_edit_auto_lint.py — file-edit auto-formatter', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'post_edit_auto_lint.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should import common.load_hook_input', () => {
      expect(content).toContain('from common import load_hook_input');
    });

    test('should define TS_JS file extension set', () => {
      expect(content).toContain('TS_JS');
      expect(content).toContain('".ts"');
      expect(content).toContain('".tsx"');
      expect(content).toContain('".js"');
      expect(content).toContain('".jsx"');
      expect(content).toContain('".mjs"');
    });

    test('should define PYTHON file extension set', () => {
      expect(content).toContain('PYTHON');
      expect(content).toContain('".py"');
    });

    test('should define SHELL file extension set', () => {
      expect(content).toContain('SHELL');
      expect(content).toContain('".sh"');
    });

    test('should support biome formatter for TypeScript/JavaScript', () => {
      expect(content).toContain('"biome"');
    });

    test('should fall back to prettier when biome is not available', () => {
      expect(content).toContain('"prettier"');
    });

    test('should support oxlint for TypeScript/JavaScript linting', () => {
      expect(content).toContain('"oxlint"');
    });

    test('should support ruff for Python formatting and linting', () => {
      expect(content).toContain('"ruff"');
    });

    test('should support shellcheck for shell script linting', () => {
      expect(content).toContain('"shellcheck"');
    });

    test('should use shutil.which to check tool availability', () => {
      expect(content).toContain('shutil.which(');
    });

    test('should filter out empty/clean lint output', () => {
      // Avoids producing noise when there are no issues
      expect(content).toContain('0 warnings and 0 errors');
    });

    test('should filter ruff "all checks passed" output', () => {
      expect(content).toContain('all checks passed');
    });

    test('should output additionalContext via hookSpecificOutput on issues', () => {
      expect(content).toContain('hookSpecificOutput');
      expect(content).toContain('additionalContext');
    });

    test('should always exit 0 (PostToolUse hook must not block)', () => {
      expect(content).toContain('sys.exit(0)');
      // Must not exit 2 (which would block the tool call)
      expect(content).not.toContain('sys.exit(2)');
    });

    test('should handle file not found gracefully', () => {
      // Exits early if file does not exist after edit
      expect(content).toContain('path.exists()');
    });

    test('should skip non-source file extensions gracefully', () => {
      // Only processes files in the defined extension sets
      expect(content).toContain('suffix not in');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // post_git_push_ci.py
  // ──────────────────────────────────────────────────────────────
  describe('post_git_push_ci.py — CI monitor after git push', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'post_git_push_ci.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should import helper functions from common', () => {
      expect(content).toContain('from common import');
    });

    test('should only trigger on git push commands', () => {
      expect(content).toContain('"git push"');
    });

    test('should skip --help and --dry-run invocations', () => {
      expect(content).toContain('--help');
      expect(content).toContain('--dry-run');
    });

    test('should define success patterns for push output', () => {
      expect(content).toContain('success_patterns');
      // Regex-escaped form used in the pattern list
      expect(content).toContain('\\[new branch\\]');
    });

    test('should define error patterns to skip on failed pushes', () => {
      expect(content).toContain('error_patterns');
      expect(content).toContain('rejected');
    });

    test('should use CI helpers from common', () => {
      expect(content).toContain('get_latest_run');
      expect(content).toContain('watch_ci_run');
      expect(content).not.toContain('def get_latest_run(');
      expect(content).not.toContain('def watch_ci_run(');
    });

    test('common.py should define git push CI helpers', () => {
      expect(commonContent).toContain('def get_current_branch(');
      expect(commonContent).toContain('def get_latest_run(');
      expect(commonContent).toContain('def watch_ci_run(');
    });

    test('should use gh run list to query workflow runs', () => {
      // Invoked via subprocess list: ["gh", "run", "list", ...]
      expect(commonContent).toContain('"run", "list"');
    });

    test('should use gh run view to poll run status', () => {
      expect(commonContent).toContain('"run", "view"');
    });

    test('should handle timeout when CI takes too long', () => {
      expect(commonContent).toContain('"timeout"');
    });

    test('should always exit 0 (PostToolUse must not block)', () => {
      expect(content).toContain('sys.exit(0)');
      expect(content).not.toContain('sys.exit(2)');
    });
  });
});

// post_pr_ci_watch.py, post_pr_ai_review.py, and pre_exit_plan_ai_review.py are covered in
// test/hooks-post-pr-tools.test.js (kept separate to respect file-length).
