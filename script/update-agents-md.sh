#!/usr/bin/env bash
#
# AGENTS.md の自動生成セクションをリポジトリの現在の状態から再生成する。
# <!-- BEGIN AUTO-GENERATED --> 〜 <!-- END AUTO-GENERATED --> 間を置換。
#
# Usage: bash script/update-agents-md.sh [--check]
#   --check: 差分があるか確認のみ（変更しない）。差分があれば exit 1。

set -euo pipefail

AGENTS_MD="AGENTS.md"
CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

# --- Guard ---
if [[ ! -f "$AGENTS_MD" ]] || ! grep -q "BEGIN AUTO-GENERATED" "$AGENTS_MD"; then
  echo "⏭️ スキップ（$AGENTS_MD に AUTO-GENERATED マーカーなし）"
  exit 0
fi

# --- 1. Tech stack ---
NODE_VER=$(jq -r '.engines.node // empty' package.json 2>/dev/null)
PM="npm"
[[ -f "pnpm-lock.yaml" ]] && PM="pnpm"
[[ -f "yarn.lock" ]] && PM="yarn"
{ [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; } && PM="bun"

HAS_NIX=false
[[ -f "nix/flake.nix" ]] && HAS_NIX=true

# --- 2. Collect directories (dot dirs + regular dirs) ---
collect_dirs() {
  local dirs=""
  # Dot directories (filtered)
  for d in .*/; do
    case "$d" in
      ./|../|.git/|.git-*/) continue ;;
    esac
    local name="${d%/}"
    # Sub-categorize known dot dirs
    case "$name" in
      .agents)          dirs+="| \`.agents/\`           | AI agent skills and configurations               |"$'\n' ;;
      .claude)
        [[ -d ".claude/agents" ]]  && dirs+="| \`.claude/agents/\`    | Claude Code specialized agents                   |"$'\n'
        dirs+="| \`.claude/commands/\`  | Claude Code slash commands                       |"$'\n'
        dirs+="| \`.claude/hooks/\`     | Pre/post hook scripts for quality enforcement    |"$'\n'
        [[ -d ".claude/plugins" ]] && dirs+="| \`.claude/plugins/\`   | Claude Code plugin configuration                 |"$'\n'
        [[ -d ".claude/rules" ]]   && dirs+="| \`.claude/rules/\`     | Claude Code rules for development standards      |"$'\n'
        [[ -d ".claude/skills" ]]  && dirs+="| \`.claude/skills/\`    | Claude Code skill definitions                    |"$'\n'
        ;;
      .codex)           dirs+="| \`.codex/\`            | Codex AI agent configuration                     |"$'\n' ;;
      .context)         dirs+="| \`.context/\`          | Shared intermediate artifacts (complexity reports etc.) |"$'\n' ;;
      .cursor)          dirs+="| \`.cursor/\`           | Cursor editor settings                           |"$'\n' ;;
      .devcontainer)    dirs+="| \`.devcontainer/\`     | DevContainer configuration and Dockerfile        |"$'\n' ;;
      .gemini)          dirs+="| \`.gemini/\`           | Gemini AI agent configuration                    |"$'\n' ;;
      .github)
        local wf_count
        wf_count=$(find .github/workflows -maxdepth 1 -name '*.yml' 2>/dev/null | wc -l | tr -d ' ')
        dirs+="| \`.github/workflows/\` | GitHub Actions CI/CD workflows ($wf_count workflows)    |"$'\n'
        ;;
      .husky)           dirs+="| \`.husky/\`            | Git hooks (pre-commit, commit-msg)               |"$'\n' ;;
      .vscode)          dirs+="| \`.vscode/\`           | VS Code workspace settings                       |"$'\n' ;;
    esac
  done

  # Regular directories
  for d in */; do
    case "$d" in node_modules/|coverage/|.git/|reports/|result/) continue ;; esac
    local name="${d%/}"
    local purpose=""
    case "$name" in
      brew)        purpose="Homebrew package management (Linux only)"         ;;
      credentials) purpose="Credential templates and filtering documentation" ;;
      docs)        purpose="Documentation and ADRs"                           ;;
      dot)         purpose="Dotfiles (DevContainer .zshrc, peco)"             ;;
      eslint)      purpose="ESLint configuration and plugins"                 ;;
      git)         purpose="Git hooks and configuration"                      ;;
      next)        purpose="Next.js project templates"                        ;;
      nix)         purpose="nix-darwin + home-manager (macOS environment)"    ;;
      npm)         purpose="npm global configuration and library management"  ;;
      script)      purpose="Utility shell scripts"                            ;;
      templates)   purpose="Workflow, testing, and dotfile templates"          ;;
      test)        purpose="Test suites (Jest unit, BATS integration)"        ;;
      vscode)      purpose="VS Code extensions list"                          ;;
      *)           purpose="$name"                                            ;;
    esac
    dirs+="| \`$name/\` | $purpose |"$'\n'
  done
  echo -n "$dirs"
}

# --- 3. Collect commands ---
collect_commands() {
  local cmds=""
  for cmd in .claude/commands/*.md; do
    [[ ! -f "$cmd" ]] && continue
    local base
    base=$(basename "$cmd" .md)
    [[ "$base" == "README" ]] && continue
    local desc
    desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: */, ""); print; exit}' "$cmd")
    [[ -z "$desc" ]] && desc="(no description)"
    cmds+="| \`/$base\` | $desc |"$'\n'
  done
  echo -n "$cmds"
}

# --- 4. Collect workflows ---
collect_workflows() {
  local wfs=""
  for wf in .github/workflows/*.yml; do
    [[ ! -f "$wf" ]] && continue
    local base
    base=$(basename "$wf")
    local name
    name=$(grep -m1 '^name:' "$wf" | sed 's/^name: *//' | tr -d "'\"")
    [[ -z "$name" ]] && name="(unnamed)"
    wfs+="| \`$base\` | $name |"$'\n'
  done
  echo -n "$wfs"
}

# --- 5. Collect quality gates ---
collect_quality_gates() {
  local gates=""
  local scripts=("format:check" "lint" "test" "shellcheck" "typecheck" "type-check" "tsc")
  local purposes=("Code formatting validation" "Code quality validation" "Unit test execution" "Shell script validation" "Type checking" "Type checking" "Type checking")

  for i in "${!scripts[@]}"; do
    local key="${scripts[$i]}"
    local val
    val=$(jq -r --arg k "$key" '.scripts[$k] // empty' package.json 2>/dev/null)
    if [[ -n "$val" ]]; then
      gates+="| \`$key\` | \`$val\` | ${purposes[$i]} |"$'\n'
    fi
  done
  echo -n "$gates"
}

# --- 6. Collect extra test scripts ---
collect_extra_tests() {
  local extras=""
  for key in "test:integration" "test:coverage" "test:all"; do
    local val
    val=$(jq -r --arg k "$key" '.scripts[$k] // empty' package.json 2>/dev/null)
    [[ -n "$val" ]] && extras+="$key"$'\n'
  done
  echo -n "$extras"
}

# --- 7. Collect hooks ---
collect_hooks() {
  local hooks_out=""
  for hook in .claude/hooks/*.py; do
    [[ ! -f "$hook" ]] && continue
    local base
    base=$(basename "$hook")
    local trigger="" purpose=""

    # Determine trigger and purpose from filename pattern
    case "$base" in
      block_git_no_verify.py)      trigger="Pre git commit/push"; purpose="Block \`--no-verify\` and \`HUSKY=0\`" ;;
      pre_git_quality_gates.py)    trigger="Pre git commit/push"; purpose="Auto-detect and run quality gates" ;;
      block_config_edit.py)        trigger="Pre edit";            purpose="Protect configuration files" ;;
      block_dangerous_commands.py) trigger="Pre Bash";            purpose="Block destructive commands" ;;
      post_edit_auto_lint.py)      trigger="Post edit";           purpose="Auto-format and lint" ;;
      post_git_push_ci.py)         trigger="Post git push";       purpose="Monitor CI status" ;;
      post_pr_ai_review.py)        trigger="Post PR creation";    purpose="Run AI code review" ;;
      post_pr_ci_watch.py)         trigger="Post PR creation";    purpose="Monitor PR CI status" ;;
      post_commit_adr_reminder.py) trigger="Post git commit";     purpose="Remind ADR for architectural changes" ;;
      pre_exit_plan_ai_review.py)  trigger="Pre ExitPlanMode";    purpose="AI review before plan exit" ;;
      stop_test_verification.py)   trigger="Stop";                purpose="Verify test results on session end" ;;
      *)
        # Fallback: infer from prefix
        case "$base" in
          block_*) trigger="Pre Bash" ;;
          pre_*)   trigger="Pre" ;;
          post_*)  trigger="Post" ;;
          stop_*)  trigger="Stop" ;;
          *)       trigger="Unknown" ;;
        esac
        purpose="${base%.py}"
        ;;
    esac

    hooks_out+="| \`$base\` | $trigger | $purpose |"$'\n'
  done
  echo -n "$hooks_out"
}

# --- 8. Build auto-generated content ---
DIRS=$(collect_dirs)
COMMANDS=$(collect_commands)
WORKFLOWS=$(collect_workflows)
QUALITY_GATES=$(collect_quality_gates)
HOOKS=$(collect_hooks)

# Extra test info
EXTRA_TESTS=$(collect_extra_tests)
EXTRA_LINE=""
if [[ -n "$EXTRA_TESTS" ]]; then
  EXTRA_LINE="Additional test commands:"
  echo "$EXTRA_TESTS" | while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    case "$t" in
      test:integration) EXTRA_LINE+=" \`$t\` (BATS)," ;;
      test:coverage)    EXTRA_LINE+=" \`$t\` (Jest + coverage)," ;;
      test:all)         EXTRA_LINE+=" \`$t\` (unit + integration)," ;;
      *)                EXTRA_LINE+=" \`$t\`," ;;
    esac
  done
fi

# Build the content
AUTO_CONTENT="<!-- This section is auto-generated by /repo-maintenance. Do not edit manually. -->

## Repository Overview

Development infrastructure template repository providing DevContainer images, CI/CD workflows, Claude Code commands/hooks, and standardized tooling for all repositories.

- **Tech Stack**: Node.js (${NODE_VER:-N/A}), Jest, BATS, ESLint, Prettier
- **Package Manager**: $PM
- **Base Image**: \`ghcr.io/keito4/config-base:latest\`
- **Release**: semantic-release (Conventional Commits)"

if [[ "$HAS_NIX" == "true" ]]; then
  AUTO_CONTENT+="
- **macOS Environment**: nix-darwin + home-manager (\`nix/flake.nix\`)"
fi

AUTO_CONTENT+="

## Project Structure

| Directory | Purpose |
| --- | --- |
${DIRS}
## Available Commands

| Command | Description |
| --- | --- |
${COMMANDS}
## CI/CD Workflows

| Workflow | Purpose |
| --- | --- |
${WORKFLOWS}
## Quality Gates

The following scripts are auto-detected and run before git commit/push:

| Script | Command | Purpose |
| --- | --- | --- |
${QUALITY_GATES}
Additional test commands: \`test:integration\` (BATS), \`test:coverage\` (Jest + coverage), \`test:all\` (unit + integration)

## Hooks

| Hook | Trigger | Purpose |
| --- | --- | --- |
${HOOKS}
## Development Standards

### Code Quality Requirements

- **Test-Driven Development (TDD)**: Red -> Green -> Refactor methodology with 70%+ line coverage requirement
- **Static Quality Gates**: Automated linting, formatting, security analysis, and license checking
- **Git Workflow**: Conventional commits, branch naming conventions, and pull request requirements
- **Release Types Required for Tooling Changes**: Commits that touch \`.codex/**\`, \`.devcontainer/codex*\`, \`package*.json\`, or \`npm/global.json\` must use release-triggering types (\`feat\` / \`fix\` / \`perf\` / \`revert\` / \`docs\`). commitlint blocks \`chore\` etc. to align with semantic-release."

# --- 9. Replace markers ---
# Extract HEAD (up to and including BEGIN marker) and TAIL (from END marker)
HEAD=$(sed '/<!-- BEGIN AUTO-GENERATED -->/q' "$AGENTS_MD")
TAIL=$(sed -n '/<!-- END AUTO-GENERATED -->/,$p' "$AGENTS_MD")

NEW_CONTENT="${HEAD}
${AUTO_CONTENT}

${TAIL}"

if [[ "$CHECK_ONLY" == "true" ]]; then
  # Write to temp file and format for accurate comparison
  TMPFILE=$(mktemp /tmp/agents-md-check-XXXXX.md)
  trap 'rm -f "$TMPFILE"' EXIT
  echo "$NEW_CONTENT" > "$TMPFILE"
  if command -v npx >/dev/null 2>&1; then
    npx prettier --write "$TMPFILE" >/dev/null 2>&1 || true
  fi
  if ! diff -q "$AGENTS_MD" "$TMPFILE" >/dev/null 2>&1; then
    echo "⚠️ AGENTS.md 自動生成セクションに差分があります"
    diff "$AGENTS_MD" "$TMPFILE" | head -30
    exit 1
  else
    echo "✅ AGENTS.md 自動生成セクション: 最新"
    exit 0
  fi
fi

echo "$NEW_CONTENT" > "$AGENTS_MD"

# Run prettier if available
if command -v npx >/dev/null 2>&1; then
  npx prettier --write "$AGENTS_MD" >/dev/null 2>&1 || true
fi

echo "🔧 AGENTS.md 自動生成セクションを更新しました"
