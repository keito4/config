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

  // ──────────────────────────────────────────────────────────────
  // post_pr_ci_watch.py
  // ──────────────────────────────────────────────────────────────
  describe('post_pr_ci_watch.py — CI monitor after PR creation', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'post_pr_ci_watch.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should import extract_pr_url from common', () => {
      expect(content).toContain('extract_pr_url');
    });

    test('should only trigger on gh pr create commands', () => {
      expect(content).toContain('"gh pr create"');
    });

    test('should skip help invocations via is_help_command', () => {
      expect(content).toContain('is_help_command');
    });

    test('should extract PR number from output', () => {
      // pr_info should unpack four values including the PR number
      expect(content).toContain('pr_number');
    });

    test('should use get_pr_checks helper from common', () => {
      expect(content).toContain('get_pr_checks');
      expect(content).not.toContain('def get_pr_checks(');
      expect(commonContent).toContain('def get_pr_checks(');
    });

    test('should use gh pr checks to query check results', () => {
      // Invoked via subprocess list: ["gh", "pr", "checks", ...]
      expect(commonContent).toContain('"pr", "checks"');
    });

    test('should handle "success" conclusion', () => {
      expect(content).toContain('"success"');
    });

    test('should handle "failure" conclusion', () => {
      expect(content).toContain('"failure"');
    });

    test('should handle "timeout" when CI takes too long', () => {
      expect(content).toContain('"timeout"');
    });

    test('should handle "no_checks" when CI is not configured', () => {
      expect(content).toContain('"no_checks"');
    });

    test('should prompt the user to fix CI failures on the same branch', () => {
      expect(content).toContain('このブランチで修正');
    });

    test('should always exit 0 (PostToolUse must not block)', () => {
      expect(content).toContain('sys.exit(0)');
      expect(content).not.toContain('sys.exit(2)');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // post_pr_ai_review.py
  // ──────────────────────────────────────────────────────────────
  describe('post_pr_ai_review.py — AI review after PR creation', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'post_pr_ai_review.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should import extract_pr_url from common', () => {
      expect(content).toContain('extract_pr_url');
    });

    test('should only trigger on gh pr create commands', () => {
      expect(content).toContain('"gh pr create"');
    });

    test('should check for codex availability via common helper', () => {
      expect(content).toContain('command_available("codex")');
      expect(commonContent).toContain('def command_available(');
    });

    test('should check for gemini availability via common helper', () => {
      expect(content).toContain('command_available("gemini")');
    });

    test('should skip gracefully when neither AI tool is installed', () => {
      expect(content).toContain('not has_codex and not has_gemini');
    });

    test('should define run_codex_review function', () => {
      expect(content).toContain('def run_codex_review(');
    });

    test('should define run_gemini_review function', () => {
      expect(content).toContain('def run_gemini_review(');
    });

    test('should define post_pr_comment function', () => {
      expect(content).toContain('def post_pr_comment(');
    });

    test('should define check_for_issues function', () => {
      expect(content).toContain('def check_for_issues(');
    });

    test('should detect "patch is incorrect" as a problem indicator', () => {
      expect(content).toContain('patch is incorrect');
    });

    test('should use gh pr comment to post review results', () => {
      // Invoked via subprocess list: ["gh", "pr", "comment", ...]
      expect(content).toContain('"pr", "comment"');
    });

    test('should run codex and gemini in parallel via common helper', () => {
      expect(content).toContain('run_parallel_reviews');
      expect(commonContent).toContain('ThreadPoolExecutor');
    });

    test('should include a timeout for AI review calls', () => {
      expect(content).toContain('timeout=600');
    });

    test('common.py should handle AI command timeouts gracefully', () => {
      expect(commonContent).toContain('TimeoutExpired');
    });

    test('should always exit 0 (PostToolUse must not block)', () => {
      expect(content).toContain('sys.exit(0)');
      expect(content).not.toContain('sys.exit(2)');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // pre_exit_plan_ai_review.py
  // ──────────────────────────────────────────────────────────────
  describe('pre_exit_plan_ai_review.py — AI plan review before ExitPlanMode', () => {
    let content;

    beforeAll(() => {
      content = fs.readFileSync(path.join(hooksDir, 'pre_exit_plan_ai_review.py'), 'utf8');
    });

    test('should have shebang line', () => {
      expect(content.startsWith('#!/usr/bin/env python3')).toBe(true);
    });

    test('should import load_hook_input from common', () => {
      expect(content).toContain('load_hook_input');
    });

    test('should only trigger when tool_name is ExitPlanMode', () => {
      expect(content).toContain('"ExitPlanMode"');
    });

    test('should skip gracefully when neither AI tool is installed', () => {
      expect(content).toContain('not has_codex and not has_gemini');
    });

    test('should check AI tool availability via common helper', () => {
      expect(content).toContain('command_available("codex")');
      expect(content).toContain('command_available("gemini")');
    });

    test('should look for plan files in ~/.claude/plans directory', () => {
      expect(content).toContain('.claude/plans');
    });

    test('should detect plan files by .md extension', () => {
      expect(content).toContain('*.md');
    });

    test('should read the most recently modified plan file', () => {
      expect(content).toContain('os.path.getmtime');
    });

    test('should define run_codex_review for plan analysis', () => {
      expect(content).toContain('def run_codex_review(');
    });

    test('should define run_gemini_review for plan analysis', () => {
      expect(content).toContain('def run_gemini_review(');
    });

    test('should check for "plan needs revision" verdict from AI', () => {
      expect(content).toContain('plan needs revision');
    });

    test('should check for "plan is ready" verdict from AI', () => {
      expect(content).toContain('plan is ready');
    });

    test('should block with exit 2 when revision is needed', () => {
      expect(content).toContain('sys.exit(2)');
    });

    test('should allow with exit 0 when plan is approved', () => {
      expect(content).toContain('sys.exit(0)');
    });

    test('should run both AI reviews with a 10-minute timeout', () => {
      expect(content).toContain('timeout=600');
    });

    test('should propagate review_prompt that includes plan content', () => {
      expect(content).toContain('plan_content');
      expect(content).toContain('review_prompt');
    });

    test('should handle file read errors gracefully', () => {
      expect(content).toContain('except Exception');
    });
  });
});
