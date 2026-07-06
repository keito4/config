'use strict';

const fs = require('fs');
const path = require('path');

const hooksDir = path.join(__dirname, '../.claude/hooks');
const commonContent = fs.readFileSync(path.join(hooksDir, 'common.py'), 'utf8');

describe('Post-PR and pre-exit-plan hooks — content and structure', () => {
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
