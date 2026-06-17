---
description: Setup comprehensive CI/CD workflows for your repository
allowed-tools: Read, Bash(script/setup-ci.sh:*), Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(pnpm:*), Skill
argument-hint: '[--type nextjs|nodejs|terraform|monorepo] [--level minimal|standard|comprehensive] [--dry-run]'
---

# CI/CD Setup Command

The executable source of truth is `script/setup-ci.sh`.

Run the script with the user-provided arguments:

```bash
script/setup-ci.sh $ARGUMENTS
```

## Responsibilities

- Detect project type when `--type` is omitted.
- Detect package manager from lockfiles.
- Create or refresh `.github/workflows/ci.yml`.
- Copy managed supporting workflow templates when missing.
- Support `--dry-run` for inspection-only execution.

## Levels

| Level         | Behavior                                |
| ------------- | --------------------------------------- |
| minimal       | Quality, test, and build basics         |
| standard      | Minimal plus security audit             |
| comprehensive | Currently aliases standard until needed |

After writing workflows, run `actionlint` if available and verify repository quality gates.
