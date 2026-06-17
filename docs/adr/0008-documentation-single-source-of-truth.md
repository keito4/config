# ADR 0008: Documentation Single Source Of Truth

## Status

Accepted

## Context

README.md, `.claude/commands/README.md`, AGENTS.md, and setup documents duplicated directory trees, command lists, workflow lists, hooks, and quality-gate tables. These lists change frequently and had already drifted across files.

The repository already has `script/update-agents-md.sh`, which generates the repository overview, directory map, command list, agent list, skill list, workflow list, quality gates, and hook tables into AGENTS.md.

## Decision

Generated or inventory-like documentation has one canonical source:

- AGENTS.md auto-generated section is the canonical repository inventory.
- README.md is a short entrypoint and link hub.
- `.claude/commands/README.md` documents command-authoring conventions only.
- Script, DevContainer, template, credential, and setup details live in their nearest domain README.
- Commitlint configuration is canonical at the repository root. `templates/commitlint.config.js` must state that it mirrors the root configuration.

Hand-written duplicate directory trees, command catalogs, workflow catalogs, hook catalogs, and quality-gate catalogs are not allowed.

## Consequences

### Positive

- Drift-prone lists have one source of truth.
- README.md stays small enough to scan.
- Command documentation can focus on conventions instead of stale catalogs.
- Template and setup documentation live near the files they describe.

### Negative

- Readers must follow links for detailed setup procedures.
- Changes to generated catalogs require running `script/update-agents-md.sh`.

### Mitigation

- Keep source-of-truth links in README.md.
- Run `bash script/update-agents-md.sh --check` in maintenance and pre-PR verification.
- Save docs-consistency review artifacts under `.context/`.
