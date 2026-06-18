# ADR 0010: CI workflow consolidation

## Status

Accepted

## Context

The repository had several CI/CD maintenance costs that were growing together:

- `container-security.yml` ran Trivy three times against the same local image to produce SARIF, a table summary, and the critical-vulnerability failure.
- `rebuild-docker-cache.yml` duplicated Docker build setup and release-image build logic that already existed in `docker-image.yml`.
- Docker setup steps for QEMU, Buildx, and GHCR login were repeated across release workflows.
- `ci.yml` embedded the PR size labeling logic directly in the workflow.

These patterns made workflow changes expensive and increased the chance of behavior drift.

## Decision

Consolidate the CI/CD workflow surface as follows:

- Keep a single Trivy scan and derive the GitHub summary and critical-vulnerability failure from its SARIF output.
- Fold the weekly no-cache Docker cache rebuild into `docker-image.yml` using a `schedule` trigger and `workflow_dispatch` `no_cache` input.
- Extract Docker setup to `.github/actions/setup-docker-build/`.
- Extract PR size labeling to `.github/actions/pr-size-check/`.
- Keep `.trivyignore` review visible in scheduled maintenance with a lightweight review-date check.

## Consequences

### Positive

- The root workflow count decreases by one.
- Container security scanning avoids repeated scans of the same image.
- Docker setup and PR-size behavior have one implementation point.

### Negative

- `docker-image.yml` now owns both release builds and no-cache cache rebuilds, so the workflow has more branching logic.
- The no-cache rebuild path still needs a post-merge `workflow_dispatch` smoke run because it writes GHCR state.

### Mitigation

- Contract tests assert the workflow count, Docker composite usage, PR-size action usage, and single Trivy action invocation.
- The no-cache path skips release creation and only updates the image/cache tags.
