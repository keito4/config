# ADR 0007: Separate Claude Pull Request Creation From Claude Bash Tools

## Status

Accepted

## Context

Claude Code Action can push a branch for issue-driven work, but creating the pull request with `gh pr create` from inside Claude requires exposing `GH_TOKEN` to Claude's Bash subprocess environment. That token is broader than the single PR creation operation and can also be visible to other allowed Bash commands such as package manager commands.

The action exposes a `branch_name` output. GitHub Actions can use that output after Claude finishes to perform deterministic repository operations without making the PR-creation token available to Claude-authored shell commands.

## Decision

Issue-driven Claude workflows will let Claude create commits and push its branch, then a separate GitHub Actions shell step will create the pull request from `steps.<claude-step>.outputs.branch_name`.

Scheduled maintenance runs in trusted agent mode and can update workflow files, so it must set and check out `CLAUDE_BRANCH` before invoking the Claude action and must provide `github_token: ${{ secrets.CLAUDE_PR_GITHUB_TOKEN }}`. The maintenance command uses that branch name for checkout and push. Because `/repo-maintenance --create-pr` delegates to `script/repo-maintenance.sh`, scheduled maintenance allows `Bash(gh pr create:*)` for that script path. The post-Claude step remains as an idempotent fallback and skips when a PR already exists for the branch.

Issue-driven Claude workflow prompts must tell Claude not to run `gh pr create`. Issue-driven Claude allowed tools must not include `Bash(gh pr create:*)`, and the Claude action must not receive `github_token: ${{ github.token }}` as an input. The post-Claude step is responsible for:

- detecting whether a PR already exists for the branch,
- checking that the branch was actually pushed,
- creating the PR with the relevant issue or maintenance context,
- using `CLAUDE_PR_GITHUB_TOKEN` as `GH_TOKEN` only in deterministic maintenance PR creation.

## Consequences

This reduces token exposure in Claude-controlled Bash commands and makes PR creation easier to test with workflow contract tests.

Scheduled maintenance requires `CLAUDE_PR_GITHUB_TOKEN` with the minimum repository permissions needed to push maintenance branches, update workflow files, and create pull requests. That token is exposed only to the trusted maintenance workflow, not to issue-driven Claude workflows. Issue-driven workflows do not pass `github_token: ${{ github.token }}` into Claude-controlled execution.

The workflow now depends on the Claude Code Action `branch_name` output. If the action changes that output contract, the post-Claude PR creation step will skip or fail visibly instead of silently asking Claude to create a PR itself.
