---
name: update
description: Update DevContainer to latest config-base image and create PR
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(curl:*), Bash(jq:*)
argument-hint: [--version X.Y.Z]
---

# DevContainer Update Workflow

## Step 1: Load Settings

設定ファイルが存在する場合は読み込む：

Check settings file: !`test -f .claude/config-base-sync.local.md && echo "EXISTS" || echo "MISSING"`

設定ファイルが存在する場合:

- Read `.claude/config-base-sync.local.md` to load user configuration
- Extract `baseBranch`, `autoCreatePR`, `updateScope` from YAML frontmatter
- Validate settings values (baseBranch must be valid git branch, autoCreatePR must be boolean, updateScope must be one of: all, image-only, minimal)
- If validation fails, stop and report the error to the user

設定ファイルが存在しない場合:

- Use defaults: baseBranch="main", autoCreatePR=true, updateScope="all"

## Step 2: Determine Target Version

引数が提供されている場合（`$ARGUMENTS` starts with `--version`）:

- Extract version number from arguments
- Target version = specified version

引数がない場合:

- Fetch latest release from GitHub API:
  ```bash
  gh api repos/keito4/config/releases/latest --jq '.tag_name'
  ```
- Target version = latest release tag (remove 'v' prefix)

## Step 3: Check Current Version

Read `.devcontainer/devcontainer.json` to check current image version.

Extract current version from `image` field (format: `ghcr.io/keito4/config-base:X.Y.Z`)

If current version == target version:

- Report: "Already on latest version X.Y.Z. No update needed."
- Stop execution

## Step 4: Check Git Status

Check for uncommitted changes:

```bash
git status --porcelain
```

If there are uncommitted changes:

- Report error: "Uncommitted changes detected. Please commit or stash changes before updating."
- List the uncommitted files
- Stop execution

## Step 5: Create Update Branch

Create new branch for the update:

```bash
git checkout -b update-config-base-{target-version}
```

If branch already exists:

- Report error: "Branch 'update-config-base-{target-version}' already exists."
- Suggest: "Delete the branch with: git branch -D update-config-base-{target-version}"
- Stop execution

## Step 6: Read Template Configuration

Read the reference configuration from this repository:

- Read `/Users/keito4/develop/github.com/keito4/config/.devcontainer/devcontainer.json`
- Read `/Users/keito4/develop/github.com/keito4/config/.devcontainer/codex-config.json`
- Read `/Users/keito4/develop/github.com/keito4/config/.devcontainer/claude-settings.json`

Extract recommended configuration based on `updateScope`:

- **all**: Update image, features, mounts, postCreateCommand, customizations, remoteEnv
- **image-only**: Update only the image field
- **minimal**: Update image and features only

## Step 7: Update devcontainer.json

Based on `updateScope`, update `.devcontainer/devcontainer.json`:

1. Update `image` field to `ghcr.io/keito4/config-base:{target-version}`

2. If `updateScope` is "all" or "minimal":
   - Update `features` object with recommended features from template
   - Preserve any user-added features not in template

3. If `updateScope` is "all":
   - Update `remoteEnv` with recommended environment variables
   - Update `mounts` with recommended mounts (preserve user additions)
   - Update `customizations` with recommended VS Code settings
   - Update `postCreateCommand` if significantly different

Use the Edit tool to make precise updates to the JSON file.

## Step 8: Update Additional Config Files

If `updateScope` is "all":

- Check if `.devcontainer/codex-config.json` exists locally
  - If yes, compare with template and suggest updates if needed
- Check if `.devcontainer/claude-settings.json` exists locally
  - If yes, compare with template and suggest updates if needed

## Step 9: Report Changes

Display a summary of changes made:

- Image version: old → new
- Added features (if any)
- Updated settings (if any)
- Changed commands (if any)

## Step 10: Commit Changes

Create commit with conventional commit message:

```bash
git add .devcontainer/
git commit -m "feat: Update config-base image to v{target-version}

- Update DevContainer image from v{old-version} to v{target-version}
- Sync configuration with latest recommended settings
- Update features, mounts, and environment variables

Release notes: https://github.com/keito4/config/releases/tag/v{target-version}"
```

## Step 11: Push and Create PR

Push branch to remote:

```bash
git push -u origin update-config-base-{target-version}
```

If `autoCreatePR` is true:

- Create pull request using gh CLI:

  ```bash
  gh pr create \
    --base {baseBranch} \
    --title "feat: Update config-base to v{target-version}" \
    --body "## Summary

  Updates DevContainer configuration to use the latest config-base image.

  ### Changes
  - **Image**: ghcr.io/keito4/config-base:{old-version} → v{target-version}
  - **Configuration**: Synced with latest recommended settings

  ### Release Notes
  See: https://github.com/keito4/config/releases/tag/v{target-version}

  ### Testing
  - [ ] DevContainer builds successfully
  - [ ] All tools and features work as expected
  - [ ] CI passes

  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  "
  ```

- Report PR URL to user

If `autoCreatePR` is false:

- Report: "Branch pushed successfully. Create PR manually with:"
- Show gh pr create command for user to run

## Step 12: Final Report

Provide a complete summary:

```
✅ DevContainer update complete!

Version: v{old-version} → v{target-version}
Branch: update-config-base-{target-version}
PR: {PR-URL or "Manual creation required"}

Next steps:
1. Review the pull request
2. Test the DevContainer locally
3. Merge when ready
```

---

**Progress Reporting**: After each step, report what was done using this format:

- ✅ Step N: [Action completed]
- 🔄 Step N: [Action in progress]
- ❌ Step N: [Action failed - reason]

**Error Handling**: If any step fails:

1. Report the specific error
2. Explain what went wrong
3. Suggest corrective action
4. Stop execution (do not continue to next steps)
