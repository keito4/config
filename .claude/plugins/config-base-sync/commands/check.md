---
description: Check current and latest config-base image versions
allowed-tools: Read, Bash(gh:*), Bash(jq:*)
---

# DevContainer Version Check

## Step 1: Get Current Version

Read `.devcontainer/devcontainer.json` to extract current image version.

Look for the `image` field with format: `ghcr.io/keito4/config-base:X.Y.Z`

Extract the version number (X.Y.Z part).

If `.devcontainer/devcontainer.json` does not exist:

- Report error: "DevContainer configuration not found at .devcontainer/devcontainer.json"
- Stop execution

If `image` field is not in the expected format:

- Report current image value
- Note: "Not using config-base image or format is unexpected"

## Step 2: Get Latest Version

Fetch the latest release from GitHub API:

```bash
gh api repos/keito4/config/releases/latest --jq '.tag_name'
```

Extract version number (remove 'v' prefix if present).

If API call fails:

- Report error: "Failed to fetch latest version from GitHub"
- Suggest: "Check GitHub CLI is authenticated and network is available"
- Stop execution

## Step 3: Compare Versions

Compare current version with latest version:

If current version == latest version:

- Status: ✅ Up to date

If current version < latest version:

- Status: ⚠️ Update available

If current version > latest version:

- Status: ℹ️ Using unreleased version

## Step 4: Get Release Information

If an update is available, fetch release notes:

```bash
gh api repos/keito4/config/releases/tags/v{latest-version} --jq '.body'
```

Extract key highlights from release notes (first few lines or bullet points).

## Step 5: Display Report

Format and display the version check report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
config-base Version Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Version:  {current-version}
Latest Version:   {latest-version}
Status:           {status-icon} {status-message}

{If update available:}
Release Highlights:
{release-notes-excerpt}

Full release notes:
https://github.com/keito4/config/releases/tag/v{latest-version}

To update, run:
  /config-base-sync:update

{If up to date:}
Your DevContainer is using the latest config-base image.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Additional Information

If the user has `.claude/config-base-sync.local.md` settings:

- Read the settings file
- Display configured update preferences:
  - Base branch: {baseBranch}
  - Auto-create PR: {autoCreatePR}
  - Update scope: {updateScope}

---

**Output Style**: Use clear, readable text formatting with emojis for status indicators:

- ✅ Up to date
- ⚠️ Update available
- ℹ️ Using unreleased version
- ❌ Error

**Error Handling**: If any check fails, provide clear error message and suggest resolution.
