# Changelog Generator Command

Generate CHANGELOG.md from Conventional Commits history.

## Usage

```bash
/changelog-generator
/changelog-generator --since v1.0.0
/changelog-generator --output CHANGELOG.md
```

## What It Does

This command generates a structured CHANGELOG from git commit history:

### Commit Grouping

Automatically groups commits by type:

- **Features** (feat): New features and enhancements
- **Bug Fixes** (fix): Bug fixes and patches
- **Performance** (perf): Performance improvements
- **Breaking Changes**: BREAKING CHANGE notes
- **Documentation** (docs): Documentation updates
- **Other**: ci, chore, refactor, test, style, build

### Version Detection

- **Automatic Versioning**: Detects latest tag
- **Custom Range**: Specify start tag with `--since`
- **Unreleased Changes**: Shows commits since last tag

### Changelog Format

- **Grouped by Type**: Organized sections
- **Commit Links**: GitHub commit URLs
- **PR References**: Links to pull requests
- **Breaking Changes**: Highlighted separately
- **Contributors**: Optional contributor list

## Example Output

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Features

- Add dependency health check command ([#238](https://github.com/user/repo/pull/238))
- Add pre-PR checklist automation ([a1b2c3d](https://github.com/user/repo/commit/a1b2c3d))
- Branch cleanup utility ([4e5f6g7](https://github.com/user/repo/commit/4e5f6g7))

### Bug Fixes

- Fix coverage reporting in CI ([8h9i0j1](https://github.com/user/repo/commit/8h9i0j1))
- Resolve shellcheck warnings ([2k3l4m5](https://github.com/user/repo/commit/2k3l4m5))

### Documentation

- Update README with new commands ([#239](https://github.com/user/repo/pull/239))

## [1.0.0] - 2025-12-30

### Features

- Initial release with comprehensive CI/CD
- DevContainer configuration
- Claude Code integration

### BREAKING CHANGES

- Minimum Node.js version is now 22+
```

## Options

```bash
# Generate since specific tag
/changelog-generator --since v1.0.0

# Generate for all history
/changelog-generator --all

# Custom output file
/changelog-generator --output HISTORY.md

# Include all commit types
/changelog-generator --include-all

# Add contributors section
/changelog-generator --contributors

# Preview without writing
/changelog-generator --dry-run
```

## Conventional Commit Types

| Type     | Section          | Included by Default |
| -------- | ---------------- | ------------------- |
| feat     | Features         | ✅                  |
| fix      | Bug Fixes        | ✅                  |
| perf     | Performance      | ✅                  |
| docs     | Documentation    | ✅                  |
| BREAKING | BREAKING CHANGES | ✅                  |
| refactor | Refactoring      | ❌                  |
| test     | Tests            | ❌                  |
| ci       | CI/CD            | ❌                  |
| chore    | Chores           | ❌                  |
| style    | Style            | ❌                  |
| build    | Build            | ❌                  |

## CI Integration

```yaml
# .github/workflows/release.yml
- name: Generate Changelog
  run: |
    bash script/changelog-generator.sh --since ${{ github.event.release.tag_name }}
    git add CHANGELOG.md
    git commit -m "docs: update changelog for ${{ github.event.release.tag_name }}"
```

## Format

The generated changelog follows [Keep a Changelog](https://keepachangelog.com/) format:

- **Readable**: Human-friendly format
- **Parseable**: Machine-readable structure
- **Consistent**: Follows Conventional Commits
- **Linkable**: GitHub URLs for commits and PRs

## Benefits

- 📝 **Automated**: No manual changelog maintenance
- ✅ **Accurate**: Based on actual commits
- 🔗 **Linked**: Direct links to commits and PRs
- 📊 **Organized**: Grouped by semantic meaning
- ⚡ **Fast**: Quick generation from git log

## Implementation

This command is implemented in `script/changelog-generator.sh`.

## Requirements

- Git repository with conventional commits
- GitHub repository (for PR links)
- Git tags for version markers
