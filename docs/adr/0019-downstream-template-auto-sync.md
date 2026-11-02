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
- The whole pipeline hangs on one rotating credential, `CLAUDE_PAT`. A GitHub
  PAT expires after at most a year, and both the downstream checkout and the
  PR creation use it, so expiry stops all distribution at once.

## Amendment 2026-09-03: credential expiry must be loud

The `CLAUDE_PAT` above expired and every `sync-downstream` run failed for
months without anyone noticing (issue #1188). Two properties of the workflow
made that possible, and both are now fixed:

- Expiry surfaced inside `actions/checkout`, so the log showed only
  `Bad credentials` repeated across the matrix, naming neither the secret nor
  the remedy. A `preflight` job now probes the first
  repository in the manifest with `GET /repos/{owner}/{repo}` before the matrix
  runs, and fails once with the secret name, the required scopes, and the
  `gh secret set` command. It checks `permissions.push` rather than mere
  liveness, because a token that authenticates but cannot write to the
  downstream repositories would otherwise make the weekly check pass while the
  sync still fails — the same silently-green failure this change removes
  elsewhere. Expiry, missing repository access, and a GitHub outage are
  reported as distinct causes, since they have distinct remedies.
- Nothing reported the failure. A `notify` job now opens an issue on failure,
  following `scheduled-maintenance.yml`, and a weekly `schedule` trigger runs
  the token check alone (`plan` and `sync` are gated on
  `github.event_name != 'schedule'`) so expiry is found without waiting for a
  template push.

The general rule this pipeline now follows: a credential whose expiry is
certain needs a check that names it, and a failure nobody is told about will
be a failure nobody fixes.

### Mitigation

- Manifest schema violations fail fast in CI through the Jest suite, which
  validates the checked-in manifest against the real file tree.

## Amendment 2026-11-02: isolate the downstream credential

`CLAUDE_PAT` is also used by `fleet-workflow-guards.yml` and as a fallback in
`scheduled-maintenance.yml`. Replacing it with a token restricted to the five
downstream repositories would change those consumers' access.

Only `sync-downstream.yml` now prefers `DOWNSTREAM_SYNC_TOKEN`; it falls back
to `CLAUDE_PAT` only when the dedicated secret is absent. Preflight, downstream
checkout, and PR creation select the same secret. A configured token rejected
by GitHub fails the run with its secret name; it never retries with the legacy
credential. The other workflows retain their existing credential selection.

Provision a fine-grained PAT with resource owner `keito4` and access only to
the five repositories in `.github/sync-downstream.json`:

- `keito4/calendar_alerm`
- `keito4/effectuation`
- `keito4/intent-gate-android`
- `keito4/ohana`
- `keito4/raycast-extensions`

Repository permissions are **Contents: read and write**, **Pull requests:
read and write**, **Workflows: read and write**, and the automatically included
**Metadata: read-only**. No organization or account permissions are needed.
Use a proposed 90-day expiry and store it as the `DOWNSTREAM_SYNC_TOKEN`
repository Actions secret on `keito4/config`; do not overwrite `CLAUDE_PAT`.
The config checkout and failure notification still use `GITHUB_TOKEN`, so the
dedicated PAT does not need access to `keito4/config` itself.

Provisioning and a successful downstream run remain operational prerequisites.
Preflight probes the first manifest repository and checks classic PAT workflow
scopes when GitHub returns them; it cannot prove every fine-grained permission
or access to every manifest repository. This change does not repair or validate
the shared token for its other consumers.

## Amendment 2026-11-03: verify CI before passing the fallback gate

The fallback now requires the latest active `ci.yml` run for the PR head to
complete successfully. Missing, disabled, unfinished, failed, and unreadable
CI cannot provide a green Quality Gate. It waits up to 4200 seconds, allowing the longest explicitly timed CI path (60 minutes) plus 10 minutes of queue allowance. The consumer waits up to 4500 seconds; enclosing jobs allow 75/80 minutes. This is a finite policy, not a guarantee for jobs without explicit deadlines. This replaces
the review waiter's existing budget. The waiter verifies the fallback workflow
ID and current run attempt before accepting its Quality Gate job.

Fix the common template/helper and apply only the matching gate changes to
downstream defaults. Keep authentication, application CI, size policies and the
sync manifest unchanged. Existing mixed synchronization PRs still need their
own review; this gate correction does not approve those other changes.
