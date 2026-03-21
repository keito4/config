---
paths:
  - '.codex/**'
  - '.devcontainer/codex*'
  - 'package.json'
  - 'package-lock.json'
  - 'npm/global.json'
---

# Release-Triggering Commit Types

Commits touching these paths MUST use release-triggering types:
`feat` / `fix` / `perf` / `revert` / `docs`

commitlint blocks non-release types (`chore`, etc.) to align with semantic-release.
