# Branch Cleanup Command

Clean up merged and stale branches both locally and remotely.

## Usage

```bash
/branch-cleanup
/branch-cleanup --remote
/branch-cleanup --dry-run
```

## What It Does

This command helps maintain a clean repository by identifying and removing:

### Local Branches

- **Merged Branches**: Branches already merged into main/master
- **Stale Branches**: Branches with no activity for 30+ days
- **Gone Remote Branches**: Local branches tracking deleted remote branches

### Remote Branches (with --remote)

- **Merged PR Branches**: Branches from merged pull requests
- **Stale Remote Branches**: No activity for 30+ days
- **Abandoned Branches**: No commits, PRs, or activity

### Protected Branches

Never deletes:

- main, master, develop
- Current branch
- Branches with unmerged changes
- Branches specified in protection list

## Example Output

```
🧹 Branch Cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Current branch: feat/add-commands
🔒 Protected: main, master, develop

📊 Analysis
  • Total local branches: 15
  • Merged branches: 8
  • Stale branches (30+ days): 3
  • Up-to-date branches: 4

🗑️  Branches to delete (11):

Merged (8):
  ✓ feat/227-commitlint (merged 2 days ago)
  ✓ feat/226-common-utils (merged 2 days ago)
  ✓ feat/225-docker-in-docker (merged 2 days ago)
  ... and 5 more

Stale (3):
  ⚠ experiment/new-feature (90 days old)
  ⚠ fix/old-bug (45 days old)
  ⚠ refactor/unused (60 days old)

Delete these branches? [y/N]: y

Deleting branches...
  ✓ Deleted feat/227-commitlint
  ✓ Deleted feat/226-common-utils
  ✓ Deleted feat/225-docker-in-docker
  ✓ Deleted 8 more branches

✨ Cleanup complete! Removed 11 branches.
```

## Options

```bash
# Preview without deleting (recommended first run)
/branch-cleanup --dry-run

# Include remote branches
/branch-cleanup --remote

# Auto-confirm deletion (for CI)
/branch-cleanup --yes

# Custom staleness threshold (default: 30 days)
/branch-cleanup --stale-days 60

# Only merged branches
/branch-cleanup --merged-only
```

## Safety Features

- **Dry Run**: Preview before deletion
- **Interactive Confirmation**: Requires user approval
- **Protection List**: Never deletes protected branches
- **Unmerged Detection**: Warns about unmerged changes
- **Current Branch**: Never deletes current branch

## CI Integration

```yaml
# .github/workflows/branch-cleanup.yml
- name: Cleanup Merged Branches
  run: |
    bash script/branch-cleanup.sh --merged-only --yes
```

## Staleness Criteria

| Age    | Status     | Action |
| ------ | ---------- | ------ |
| < 30d  | Active     | Keep   |
| 30-60d | Stale      | Warn   |
| 60-90d | Very Stale | Delete |
| > 90d  | Abandoned  | Delete |

## Benefits

- 🧹 **Clean Repository**: Remove clutter
- ⚡ **Faster Operations**: Fewer branches to manage
- 👀 **Better Visibility**: Focus on active work
- 💾 **Disk Space**: Free up local storage
- 🔄 **Best Practice**: Regular maintenance habit

## Implementation

This command is implemented in `script/branch-cleanup.sh`.

## Requirements

- Git repository
- GitHub CLI (`gh`) for remote branch operations (optional)
- Proper permissions for remote deletions
