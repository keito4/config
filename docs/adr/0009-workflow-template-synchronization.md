# ADR 0009: Workflow Template Synchronization

## Status

Accepted

## Context

The repository keeps runnable workflows in `.github/workflows/` and reusable rollout templates in `templates/workflows/`. Some templates are managed copies of runnable workflows, while others are reference-only examples for downstream repositories.

Previously, workflow templates also existed under `.github/workflows/templates/`. That created two template roots and made it unclear which files were executed by this repository, copied by repo-maintenance, or only kept as references.

## Decision

Use `templates/` as the only template root.

For workflows that have both a runnable copy and a template copy, keep a lightweight CI sync check:

- `script/check-workflow-template-sync.js` owns the template-to-actual mapping.
- The check compares normalized workflow content and ignores full-line comments and blank lines.
- CI runs the check whenever workflow templates, actual workflows, or the sync script change.

Reference-only workflow templates must include a header stating that this repository does not install them under `.github/workflows/`.

## Consequences

### Positive

- Template location is unambiguous.
- Managed workflow drift is detected in CI without introducing generation machinery.
- Template guidance comments can differ from runnable workflow files.

### Negative

- The mapping is manually maintained.
- Inline comments are still part of the sync comparison.

### Mitigation

- Keep the mapping small and limited to workflows that are actually managed in both locations.
- Prefer adding reference-only headers for examples instead of adding them to the sync mapping.
