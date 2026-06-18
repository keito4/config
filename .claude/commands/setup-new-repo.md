---
description: Setup new repository with DevContainer, CI/CD, and development tools from config template
allowed-tools: Read, Bash(script/setup-new-repo.sh:*), Bash(script/setup-ci.sh:*), Bash(git:*), Bash(gh:*), Bash(npm:*), Skill
argument-hint: '<TARGET_DIR> [--type TYPE] [--minimal] [--no-devcontainer] [--no-codespaces] [--no-protection] [--license MIT|Apache-2.0] [--no-install]'
---

# New Repository Setup Command

The executable source of truth is `script/setup-new-repo.sh`.

Run the script with the user-provided arguments:

```bash
script/setup-new-repo.sh $ARGUMENTS
```

## Responsibilities

- Initialize the target directory as a Git repository when needed.
- Add config-managed editor, formatting, Claude Code, and documentation defaults.
- Create DevContainer and Codespaces configuration unless skipped.
- Delegate workflow setup to `script/setup-ci.sh` unless `--minimal` is specified.
- Install dependencies unless `--no-install` is specified.

## Safety

The script only writes missing bootstrap files or generated setup files. It does not delete user code. If an existing repository needs a broad migration, use `/repo-maintenance` after setup.
