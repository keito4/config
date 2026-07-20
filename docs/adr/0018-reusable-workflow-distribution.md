# ADR 0018: Reusable Workflow Distribution

## Status

Accepted (partially supersedes ADR 0009)

## Context

ADR 0009 manages distributed workflows as synchronized copies: the template in
`templates/workflows/` must match the runnable workflow in
`.github/workflows/`, and downstream repositories receive full copies. Every
logic change therefore requires a sync PR in each downstream repository
(automated by ADR 0017), and each of those PRs carries the entire workflow
body as reviewable diff.

GitHub reusable workflows (`workflow_call`) allow the logic to live in this
repository only. This repository is public, so private downstream
repositories can reference `keito4/config/.github/workflows/<name>.yml@main`.

## Decision

Migrate distributed workflows to a hybrid reusable model where it is safe:

- The runnable workflow in `.github/workflows/` keeps its direct triggers and
  additionally declares `workflow_call` (single combined file). Because this
  repository runs the same file, every change is exercised here before any
  downstream repository resolves it.
- The template in `templates/workflows/` becomes a thin caller stub: triggers,
  `permissions`, `concurrency` (workflow-level concurrency of a called
  workflow is not honored, so it must live in the stub), and a
  `jobs.<id>.uses: keito4/config/.github/workflows/<name>.yml@main` reference.
- Stubs carry a `# Managed by keito4/config` header; sync-downstream (ADR 0017) distributes them, and they change rarely.
- References use `@main`, not a version tag: semantic-release does not
  maintain floating major tags, downstream repositories share a single owner,
  and this repository's own CI runs the same file continuously. Revisit if
  downstream ownership diversifies.
- Converted workflows are removed from the `syncPairs` mapping in
  `script/check-workflow-template-sync.js` and from
  `check_managed_templates()` in `script/repo-maintenance.sh` (copying a stub
  over the runnable workflow would break this repository). The sync-check
  machinery itself stays for the workflows that remain copy-managed.

### Exception: workflows whose check names are protected

`quality-gate-fallback.yml` stays copy-managed. A job that runs through a
reusable workflow reports its check as `<caller job> / <called job>`, which
would rename the required status check `Quality Gate` and silently break
branch protection in every downstream repository. Copy distribution via ADR
0017 keeps the check name stable.

## Consequences

### Positive

- Workflow logic changes propagate to all downstream repositories on merge to
  `main`, with no downstream PR at all.
- Downstream diffs shrink to stub changes, which are rare.

### Negative

- `@main` means a broken merge propagates immediately; mitigation is that
  config's own CI executes the combined file on every PR.
- Behavior differences between direct and called runs (e.g. `inputs.*` being
  empty on direct triggers) must be handled with `|| default` fallbacks.

### Migration order

label-sync (1 downstream repo) first, then claude.yml,
dependabot-auto-merge.yml, and scheduled-maintenance.yml in separate PRs,
verifying one downstream repository after each batch.
