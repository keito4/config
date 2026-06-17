# Claude Commands

This directory contains Claude Code slash-command definitions.

## Source Of Truth

The command list is generated in [../../AGENTS.md](../../AGENTS.md). Do not maintain a second hand-written command catalog here.

## Command File Contract

Each command is a Markdown file named after the slash command:

```text
.claude/commands/repo-maintenance.md -> /repo-maintenance
```

Command files should include:

- a short title
- a concise description near the top, or frontmatter `description`
- required preconditions and permissions
- exact scripts or tools invoked
- verification expectations
- links to canonical docs instead of copied tables

## Authoring Rules

- Keep each command focused on one workflow.
- Prefer repository scripts under `script/` for repeatable operations.
- Put shared behavior in scripts or templates rather than duplicating shell snippets across command files.
- Store temporary artifacts under `.context/`.
- Update tests when a command participates in an enforced workflow contract.

## Related Docs

- [../../AGENTS.md](../../AGENTS.md) - generated command, hook, workflow, and quality-gate catalog
- [../../script/README.md](../../script/README.md) - script usage
- [../../templates/README.md](../../templates/README.md) - reusable templates
- [../hooks/README.md](../hooks/README.md) - hook behavior
