# ADR 0019: Downstream Template Auto-Sync

## Status

Accepted (amends ADR 0009)

## Context

ADR 0009 established `templates/` as the single template root and added a CI
check that detects drift between templates and this repository's own runnable
workflows. It did not address propagation: the five downstream repositories
(calendar_alerm, effectuation, intent-gate-android, ohana, raycast-extensions)
receive templates and `.claude/` assets (hooks, rules, settings) only when
`setup-new-repo.sh` runs or when someone manually runs `/repo-maintenance` in
the downstream repository. `check_downstream_sync()` in
`script/repo-maintenance.sh` merely prints a warning. In practice downstream
copies go stale as soon as config changes.

## Decision

Add an automated downstream sync pipeline:

- **Manifest** `.github/sync-downstream.json` declares sync groups (named sets
  of source→target file or directory mappings) and per-repository group
  opt-ins with an optional `exclude` path list. The manifest lives outside
  `templates/` because it is config-side metadata, not distributed content.
- **Sync engine** `script/sync-downstream.js` performs pure file copies from
  this repository into a downstream checkout. It never invokes git or gh, so
  its behavior is fully covered by Jest (`test/sync-downstream.test.js`).
  Python bytecode artifacts (`__pycache__/`, `*.pyc`) are always ignored.
- **Delivery** (follow-up change): a GitHub Actions workflow triggered by
  pushes to `main` that touch synced paths fans out over the manifest matrix,
  runs the sync engine against each downstream checkout, and opens an
  idempotent PR on the fixed branch `chore/config-template-sync` using
  `CLAUDE_PAT`.

Local downstream modifications are never overwritten directly: the sync only
proposes a PR, and permanent divergence is expressed as a one-line manifest
`exclude` entry instead of downstream-side marker files.

Role separation: initial placement stays with `setup-new-repo.sh`, container
builds keep baking hooks into the config-base image, and ongoing convergence
is owned by this sync pipeline.

## Consequences

### Positive

- Downstream repositories track config changes without manual
  `/repo-maintenance` runs; review happens per-repository via the sync PR.
- The manifest gives one auditable place that answers "what is managed where".
- The sync engine is testable in isolation; workflow YAML stays thin.

### Negative

- The manifest is maintained by hand; adding a repository or template requires
  a manifest edit.
- Downstream repositories with intentional local changes will keep receiving
  sync PRs until the path is excluded in the manifest.

### Mitigation

- Manifest schema violations fail fast in CI through the Jest suite, which
  validates the checked-in manifest against the real file tree.
