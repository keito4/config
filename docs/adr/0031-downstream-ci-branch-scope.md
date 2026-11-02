# ADR 0031: Preserve downstream CI branch scope during sync

## Status

Accepted

## Context

The fallback Quality Gate must verify a real CI run. Some downstream `ci.yml`
workflows accept fewer PR target branches than the shared fallback template.
Copying the template literally restores those unsupported targets after a local
fix. Expanding application CI triggers is outside this change.

## Decision

Add optional `ciBranches` to a repository entry in `.github/sync-downstream.json`.
It is a non-empty, unique array drawn from `main`, `master`, `develop`,
`pre-production`, and `production`. Calendar uses `[main, master]`, intent uses
`[main]`, and ohana uses `[main, develop]`.

Only the mapping from `templates/workflows/quality-gate-fallback.yml` to
`.github/workflows/quality-gate-fallback.yml` consumes this field. The sync engine
replaces one canonical inline `branches` list directly under top-level
`on.pull_request`. A missing or ambiguous mapping or section aborts before
copying files. The field is invalid when that mapping is excluded.

This is a limited exception to ADR 0019's literal-copy rule, not a template
language. With no field, existing file-copy and settings-sanitization behavior
remains unchanged. Application CI, other triggers and other templates retain
their bytes. `--check` renders the same result without writing.

## Consequences

- The three repositories keep their reviewed CI target scope after every sync.
- The manifest must be updated if a downstream CI branch policy changes.
- Template structure changes fail closed until this one-purpose renderer is
  reviewed and updated. Unsupported branch names require an explicit enum change.
- Contract tests use the real sync entry points to verify validation, precise
  replacement, idempotence, check mode and preservation of unrelated files.
