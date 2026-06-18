---
description: Comprehensive repository maintenance - run all health checks and updates
allowed-tools: Read, Bash(script/repo-maintenance.sh:*), Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(pnpm:*), Bash(jq:*), Skill
argument-hint: '[--mode full|quick|check-only] [--skip CATEGORY] [--create-pr]'
---

# Repository Maintenance Workflow

The executable source of truth is `script/repo-maintenance.sh`.

Run the script with the user-provided arguments:

```bash
script/repo-maintenance.sh $ARGUMENTS
```

## Modes

| Mode       | Behavior                                      |
| ---------- | --------------------------------------------- |
| full       | Runs checks and may apply managed updates     |
| quick      | Runs the important checks without broad setup |
| check-only | Read-only checks                              |

## Required Behavior

### Repository State Guard

Repository state guard runs before updates. Archived repositories switch to `check-only` and skip PR creation.

- Private repositories allow Dependency Review to be optional or skipped.
- Managed workflow templates are checked against `templates/workflows/`.

### Required Workflow Trigger Compatibility Check

Required workflow trigger compatibility is checked by `script/repo-maintenance.sh --check-required-workflows`.

- Temporary artifacts must stay under `.context/`.
- If managed config files change, report downstream sync:
  - `Downstream sync required`
  - `Repositories using config-base should run /repo-maintenance or receive a sync PR.`

## PR Creation

Use `--create-pr` when the user asks for an update PR. After the PR is created, run the CI check skill and fix failures before reporting completion.

## Related Commands

| Category    | Command                         |
| ----------- | ------------------------------- |
| Environment | `/container-health`             |
| Setup       | `/setup-ci`                     |
| Cleanup     | `/branch-cleanup`               |
| Discovery   | `/config-contribution-discover` |
