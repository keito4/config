#!/usr/bin/env bash
# Data tables sourced by script/update-agents-md.sh.
# Splitting these out keeps the orchestrator script's cyclomatic complexity low.
# shellcheck disable=SC2034 # all variables are sourced and consumed externally

declare -A DOT_DIR_PURPOSE=(
  [.agents]="AI agent skills and configurations"
  [.codex]="Codex AI agent configuration"
  [.context]="Shared intermediate artifacts (complexity reports etc.)"
  [.cursor]="Cursor editor settings"
  [.devcontainer]="DevContainer configuration and Dockerfile"
  [.gemini]="Gemini AI agent configuration"
  [.husky]="Git hooks (pre-commit, commit-msg)"
  [.vscode]="VS Code workspace settings"
  [.zsh]="Zsh configuration (aliases, completions, functions, prompt)"
)

declare -A CLAUDE_SUB_PURPOSE=(
  [agents]="Claude Code specialized agents"
  [commands]="Claude Code slash commands"
  [hooks]="Pre/post hook scripts for quality enforcement"
  [plugins]="Claude Code plugin configuration"
  [rules]="Claude Code rules for development standards"
  [skills]="Claude Code skill definitions"
)
CLAUDE_SUB_ORDER=(agents commands hooks plugins rules skills)

declare -A REG_DIR_PURPOSE=(
  [brew]="Homebrew package management (Linux only)"
  [credentials]="Credential templates and filtering documentation"
  [docs]="Documentation and ADRs"
  [dot]="Dotfiles (DevContainer .zshrc, peco)"
  [eslint]="ESLint configuration and plugins"
  [git]="Git hooks and configuration"
  [next]="Next.js project templates"
  [nix]="nix-darwin + home-manager (macOS environment)"
  [npm]="npm global configuration and library management"
  [script]="Utility shell scripts"
  [templates]="Workflow, testing, and dotfile templates"
  [test]="Test suites (Jest unit, BATS integration)"
  [vscode]="VS Code extensions list"
)

REG_DIR_SKIP=" node_modules coverage .git reports result "

declare -A QG_PURPOSE=(
  [format:check]="Code formatting validation"
  [lint]="Code quality validation"
  [test]="Unit test execution"
  [shellcheck]="Shell script validation"
  [typecheck]="Type checking"
  [type-check]="Type checking"
  [tsc]="Type checking"
)
QG_ORDER=(format:check lint test shellcheck typecheck type-check tsc)

EXTRA_TEST_LABEL_test_integration="(BATS)"
EXTRA_TEST_LABEL_test_coverage="(Jest + coverage)"
EXTRA_TEST_LABEL_test_all="(unit + integration)"

# format: filename|trigger|purpose
HOOK_TABLE=(
  "block_git_no_verify.py|Pre git commit/push|Block \`--no-verify\` and \`HUSKY=0\`"
  "pre_git_quality_gates.py|Pre git commit/push|Auto-detect and run quality gates"
  "block_config_edit.py|Pre edit|Protect configuration files"
  "block_dangerous_commands.py|Pre Bash|Block destructive commands"
  "common.py|—|Shared utility library (imported by other hooks)"
  "post_edit_auto_lint.py|Post edit|Auto-format and lint"
  "post_git_push_ci.py|Post git push|Monitor CI status"
  "post_pr_ai_review.py|Post PR creation|Run AI code review"
  "post_pr_ci_watch.py|Post PR creation|Monitor PR CI status"
  "post_commit_adr_reminder.py|Post git commit|Remind ADR for architectural changes"
  "pre_exit_plan_ai_review.py|Pre ExitPlanMode|AI review before plan exit"
  "stop_test_verification.py|Stop|Verify test results on session end"
)
