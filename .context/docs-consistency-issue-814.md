# Docs Consistency Review For Issue 814

## Scope

Reviewed documentation changes for the documentation single-source-of-truth cleanup.

## Findings

### Critical

- None.

### Important

- README now delegates generated catalogs to AGENTS.md instead of carrying hand-maintained directory, command, workflow, hook, or quality-gate tables.
- `.claude/commands/README.md` now documents command authoring conventions only; command discovery stays in AGENTS.md.
- Commitlint configuration now has one canonical implementation at the repository root. Setup docs point to `templates/commitlint.config.js`, and the template states that it mirrors the root config.
- `.cursor/rules/base.mdc` now points to `.claude/CLAUDE.md` instead of duplicating the full standard.
- Windows setup instructions are split into `docs/setup/windows.md` and linked from setup indexes.

### PR Description Notes

- The PR should include Why, What, How, and Risk sections because it changes repository documentation policy.

## Result

No remaining documentation consistency blocker was found in the changed files.
