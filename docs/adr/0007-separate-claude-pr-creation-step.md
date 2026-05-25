# ADR 0007: Separate Claude Pull Request Creation From Claude Bash Tools

## Status

Accepted

## Context

Claude Code Action can push a branch for issue-driven work, but creating the pull request with `gh pr create` from inside Claude requires exposing `GH_TOKEN` to Claude's Bash subprocess environment. That token is broader than the single PR creation operation and can also be visible to other allowed Bash commands such as package manager commands.

The action exposes `branch_name` and `github_token` outputs. GitHub Actions can use those outputs after Claude finishes to perform deterministic repository operations without making the token available to Claude-authored shell commands.

## Decision

Issue-driven Claude workflows will let Claude create commits and push its branch, then a separate GitHub Actions shell step will create the pull request from `steps.<claude-step>.outputs.branch_name`.

Claude workflow prompts must tell Claude not to run `gh pr create`. Claude allowed tools must not include `Bash(gh pr create:*)`. The post-Claude step is responsible for:

- detecting whether a PR already exists for the branch,
- creating the PR with the relevant issue or maintenance context,
- using `GH_TOKEN` only in that deterministic step.

## Consequences

This reduces token exposure in Claude-controlled Bash commands and makes PR creation easier to test with workflow contract tests.

The workflow now depends on the Claude Code Action `branch_name` output. If the action changes that output contract, the post-Claude PR creation step will skip or fail visibly instead of silently asking Claude to create a PR itself.
