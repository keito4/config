# ADR 0013: Use TAKT for Scheduled Repository Maintenance Orchestration

## Status

Accepted

## Context

Scheduled maintenance currently asks Claude Code Action to run `/repo-maintenance`
from a natural-language prompt. The executable maintenance behavior already
lives in `script/repo-maintenance.sh`, and the command contract requires that
temporary artifacts stay under `.context/` where other agents can inspect them.

TAKT provides a workflow-level state machine for AI agent execution, review
loops, command gates, and structured reports. That makes it a better fit for
the orchestration layer than a long prompt embedded in a GitHub Actions
workflow.

ADR 0007 separated pull-request creation from general issue-driven agent
execution. That boundary still matters. TAKT should not become a broad
replacement for deterministic repository operations or expose pull-request
tokens to issue-driven workflows.

## Decision

Use TAKT for scheduled repository maintenance orchestration only.

Keep `script/repo-maintenance.sh` as the executable source of truth for the
actual checks, managed updates, commits, pushes, and maintenance PR creation.
The TAKT workflow invokes a narrow wrapper script,
`script/run-takt-repo-maintenance.sh`, through a command quality gate.

Scheduled maintenance runs TAKT in pipeline mode with `--skip-git`. TAKT owns
the agent loop and report generation; `script/repo-maintenance.sh --create-pr`
and the existing post-step fallback remain responsible for branch and PR
operations.

Configure project TAKT files in `.takt/`:

- Commit `.takt/config.yaml`, `.takt/workflows/`, and workflow facet files.
- Ignore generated TAKT runtime state such as `.takt/runs/`, `.takt/tasks/`,
  and `.takt/tasks.yaml`.
- This scheduled maintenance pilot uses `--skip-git`, so TAKT shared clones are
  not created. If queued TAKT tasks are introduced later, configure their shared
  clone directory under `.context/` in the runtime environment.

Scheduled maintenance uses `TAKT_ANTHROPIC_API_KEY` first and falls back to
`ANTHROPIC_API_KEY`. The existing maintenance PR token
`CLAUDE_PR_GITHUB_TOKEN` or legacy `CLAUDE_PAT` remains separate and is used
only by trusted scheduled maintenance.

## Consequences

The scheduled workflow becomes reviewable as a TAKT YAML workflow instead of a
large prompt.

TAKT command gates require `workflow_command_gates.custom_scripts: true`. That
is intentionally enabled only for this repository-level workflow, and the gate
points to one checked-in wrapper script.

Maintainers must configure `TAKT_ANTHROPIC_API_KEY` or `ANTHROPIC_API_KEY` for
scheduled maintenance. `CLAUDE_CODE_OAUTH_TOKEN` alone is not sufficient for
the TAKT SDK provider.

Workflow template synchronization and contract tests must treat the scheduled
maintenance workflow as TAKT-backed rather than Claude Code Action-backed.
