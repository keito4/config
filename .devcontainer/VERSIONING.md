# DevContainer Semantic Versioning

This document explains how semantic versioning is implemented for the devcontainer image releases.

## Overview

The devcontainer image uses **automated semantic versioning** powered by `semantic-release`. Versions are determined automatically based on conventional commit messages, eliminating the need for manual version tagging.

## How It Works

### 1. Automatic Versioning with semantic-release

When you push to the `main` branch, the GitHub Actions workflow (`.github/workflows/docker-image.yml`) automatically:

1. Analyzes commit messages since the last release
2. Determines the next version based on commit types:
   - `feat:` → **Minor** version bump (1.0.0 → 1.1.0)
   - `fix:`, `perf:` → **Patch** version bump (1.0.0 → 1.0.1)
   - `BREAKING CHANGE:` in footer → **Major** version bump (1.0.0 → 2.0.0)
   - `docs:`, `style:`, `refactor:`, `test:`, `chore:` → No version bump
3. Builds and pushes Docker images with both version tag and `latest`
4. Creates a GitHub release with auto-generated release notes

### 2. Conventional Commits

Your commit messages must follow the conventional commits format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Examples:**

```bash
feat: add Python support to DevContainer
fix: resolve hookify plugin import error
perf: optimize Docker build cache
docs: update versioning documentation

# Breaking change (major version)
feat!: migrate to Node.js 22

BREAKING CHANGE: Node.js 20 is no longer supported
```

### 3. Manual Release (Optional)

If you need to create a manual release, use the GitHub Actions workflow dispatch:

1. Go to Actions → "Build and Release DevContainer Image"
2. Click "Run workflow"
3. Select release mode:
   - `auto` (default): Use semantic-release
   - `patch`: Force a patch release
   - `minor`: Force a minor release
   - `major`: Force a major release
   - `custom`: Specify a custom version

## Workflow Trigger

The workflow is triggered by:

- **Automatic**: Push to `main` branch
- **Manual**: workflow_dispatch (Actions UI)

**Note**: Unlike the previous proposal, tag pushes do NOT trigger builds. Versions are created automatically by semantic-release.

## Image Tags

Each release creates two tags:

- `ghcr.io/keito4/config-base:{version}` (e.g., `1.43.0`)
- `ghcr.io/keito4/config-base:latest`

### Usage Example

**Pin to a specific version (recommended for production):**

```json
{
  "image": "ghcr.io/keito4/config-base:1.43.0"
}
```

**Use latest (for development):**

```json
{
  "image": "ghcr.io/keito4/config-base:latest"
}
```

## Benefits

- **Zero manual versioning**: Versions are determined automatically
- **Consistent changelog**: Release notes generated from commit messages
- **Version tracking**: Know exactly which version you're using
- **Rollback capability**: Can easily go back to previous versions
- **Change history**: GitHub releases provide clear version history
- **Stability**: Production environments can pin to specific versions

## Configuration

The semantic-release configuration is in `.releaserc.json`:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/github"
  ]
}
```

## Commit Type Reference

| Type                           | Version Bump | Description             |
| ------------------------------ | ------------ | ----------------------- |
| `feat:`                        | **Minor**    | New feature             |
| `fix:`                         | **Patch**    | Bug fix                 |
| `perf:`                        | **Patch**    | Performance improvement |
| `feat!:` or `BREAKING CHANGE:` | **Major**    | Breaking change         |
| `docs:`                        | None         | Documentation only      |
| `style:`                       | None         | Code style (formatting) |
| `refactor:`                    | None         | Code refactoring        |
| `test:`                        | None         | Adding tests            |
| `chore:`                       | None         | Maintenance tasks       |

## Migration Status

- ✅ semantic-release configured and working
- ✅ GitHub workflow automated
- ✅ Conventional commits enforced via commitlint
- ✅ Multi-platform image builds (amd64/arm64)
- ✅ Docker layer caching enabled
- ✅ Automated release notes generation

## Notes

- The workflow skips release if no release-triggering commits are found
- Both automatic (semantic-release) and manual releases are supported
- All releases are published to GitHub Container Registry (ghcr.io)
- Release notes are automatically generated from commit history
