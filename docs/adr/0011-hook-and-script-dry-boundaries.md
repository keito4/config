# ADR 0011: Hook and Script DRY Boundaries

## Status

Accepted

## Context

The repository contains small automation scripts, Claude hooks, and long-form agent
commands. Issue #817 asks to reduce repeated implementation details without making
the operational surface harder to follow.

The highest-value duplication was in:

- CI polling logic repeated across push and pull request hooks.
- External AI review invocation and timeout handling repeated across review hooks.
- Shell output helpers repeated in `install-npm-globals.sh`.
- Managed import/export repository directories defined inline in `export.sh`.
- ShellCheck file-level exclusions kept outside the scripts they affected.

The long command documents also share some review and PR concepts, but the command
flow is intentionally narrative and has different sequencing per command. Splitting
those files before a clear 3-or-more-use abstraction would add indirection without
removing operational complexity.

## Decision

Commonize executable duplication in libraries and hooks:

- Keep CI polling and GitHub check retrieval helpers in `.claude/hooks/common.py`.
- Keep AI command availability, execution, timeout, and parallel review helpers in
  `.claude/hooks/common.py`.
- Source `script/lib/output.sh` from `script/install-npm-globals.sh`.
- Define managed import/export repository directories once in `script/lib/config.sh`.
- Replace `script/.shellcheck-exclude` with inline ShellCheck disables on zsh-only
  scripts.

Do not split large command markdown files in this phase unless a concrete shared
subcommand appears in at least three places and reduces total maintenance cost.

## Consequences

### Positive

- Hook behavior is easier to test because CI and AI subprocess logic has one home.
- ShellCheck configuration lives next to the scripts that need exceptions.
- Import/export directory ownership is visible from the shared config library.
- Command documents remain direct and readable for agents.

### Negative

- `.claude/hooks/common.py` now owns more operational behavior.
- Some command-level repetition remains intentionally duplicated.

### Mitigation

- Tests assert that hooks call the shared helpers instead of reintroducing local
  subprocess polling.
- Future command extraction should start from a repeated, executable operation, not
  from similar prose.
