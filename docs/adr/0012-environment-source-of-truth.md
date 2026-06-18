# ADR 0012: Environment Source of Truth

## Status

Accepted

## Context

Issue #819 asks to settle environment ownership before continuing refactoring.
The repository currently has several overlapping configuration surfaces:

- DevContainer `Dockerfile` installs pinned tools such as `gh`, `op`, Node.js,
  pnpm, and Supabase CLI while `devcontainer.json` can install some of them again
  through Features.
- Linux bootstrap uses `brew/LinuxBrewfile`, while macOS uses `nix/` plus
  Homebrew casks/taps.
- The repository installs dependencies with npm and `package-lock.json`, but keeps
  `pnpm-workspace.yaml` for supply-chain guardrails.
- Codex and Gemini have different MCP server sets.

The goal is to remove accidental drift without adding generators or compatibility
layers that make the repository harder to understand.

## Decision

1. DevContainer base-image tools are sourced from `.devcontainer/Dockerfile`.
   If a tool is pinned or installed there, the config repository's DevContainer
   and Codespaces definitions must not install it again as a Feature. Features are
   reserved for extra capability that is not already in the base image.
2. Linux bootstrap uses `brew/LinuxBrewfile`; macOS CLI tools use
   `nix/home/packages.nix`; macOS GUI apps, casks, and tap-dependent formulae use
   `nix/modules/homebrew.nix`. We will document this boundary instead of
   generating a shared package list.
3. This repository's package manager is npm. `package.json` declares
   `packageManager`, and `package-lock.json` remains the lockfile. The
   `pnpm-workspace.yaml` file stays only to preserve pnpm's
   `minimumReleaseAge` guardrails when pnpm is used interactively or copied into
   downstream templates.
4. Codex intentionally has the broader MCP set for repo maintenance and
   operations. Gemini intentionally has a smaller review-oriented MCP set. The
   difference is documented in `.codex/config.toml`, `.gemini/README.md`, and the
   environment diff report under `.context/`.

## Consequences

### Positive

- DevContainer rebuilds avoid duplicate installs for base-image tools.
- Package-manager intent is explicit to humans and tools.
- MCP drift is reviewable as an intentional difference rather than an unexplained
  mismatch.
- The credentials template now covers the environment variables referenced by the
  committed MCP settings.

### Negative

- Downstream repositories that still add base-image tools as Features need their
  own cleanup.
- The config repository still has multiple environment surfaces; this ADR only
  defines ownership boundaries.
- Docker image verification still requires a manual `docker-image.yml` run before
  merging changes that affect the base image itself.

### Mitigation

- Keep the `.context/issue-819-environment-diff.md` report in this PR as review
  evidence.
- BATS validates the credential template variables expected by the MCP settings.
- Future shared list generation should wait until at least three maintained
  surfaces need the same generated output.
