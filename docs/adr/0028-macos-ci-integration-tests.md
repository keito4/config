# ADR 0028: macOS integration test runner for CI

## Status

Accepted

## Context

`integration-test` (bats) ran on `ubuntu-latest` only. Several scripts
(`script/update-claude-code.sh`, `script/setup-claude.sh`) shell out to
`sed`, `mktemp`, and `realpath`, whose BSD userland behavior on macOS
differs from GNU userland on Linux. Regressions in that class slipped
through CI while it stayed green — the `script/update-claude-code.sh`
defects fixed for #1282 / #1283 (BSD `sed -i` argument parsing, and a
`PWD` symlink mismatch between `/var` and `/private/var`) were only
caught by running bats locally on macOS.

`macos-latest` runners bill at roughly 10x the rate of `ubuntu-latest`,
so running the full macOS bats suite on every PR was rejected as too
costly for the detection lead time it would buy.

## Decision

- Add an `integration-test-macos` job (`macos-latest`) that installs
  `bats-core` and a Homebrew `bash` (macOS ships bash 3.2, which is
  below the 4.3+ `script/lib/output.sh` requires) and runs the same
  bats suite as the Linux job.
- Restrict `integration-test-macos` to pushes to `main` and a weekly
  `schedule` trigger (Monday 05:00 JST), not every PR.
- Skip the `changes` (paths-filter) job on `schedule` runs, since
  `schedule` events have no diff to filter against; downstream `ubuntu`
  jobs key off `changes` and are skipped for that run instead.
- Wire `integration-test-macos` into `Quality Gate` so a macOS failure
  blocks the gate the same way a Linux integration failure does.

`ubuntu-latest` continues to run bats on every PR, so per-PR regression
detection lead time is unaffected; only BSD-userland-specific
regressions wait for the `main` push or the weekly run.

## Consequences

### Positive

- BSD-userland regressions (`sed`, `mktemp`, `realpath`, symlinked
  `/tmp`) are now caught by CI instead of only by a contributor running
  bats locally on macOS.
- The weekly schedule provides a backstop even on weeks without a
  `main` push.

### Negative

- A macOS-only regression introduced by a PR is not visible until it
  lands on `main`, not at PR review time.
- `timeout-minutes: 30` caps a hung macOS job, but failures on `main`
  still require a follow-up fix commit rather than blocking the
  original PR.

### Mitigation

- Existing Slack CI-failure alerting covers `main`-push and scheduled
  job failures.
- `Quality Gate` surfaces `integration-test-macos` results in the PR
  step summary alongside the other jobs.
