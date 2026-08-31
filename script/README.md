# Scripts

This directory contains utility scripts for managing configuration, credentials, and development workflows.

## Quick Reference

| Script                           | Purpose                                                                      | Used By                                         |
| -------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------- |
| `setup-claude.sh`                | Claude Code CLI setup                                                        | Makefile, DevContainer                          |
| `credentials.sh`                 | 1Password credential management                                              | Makefile                                        |
| `codex-config-merge.py`          | Deploy `.codex/config.toml` by deep-merging onto the local file (no symlink) | `script/lib/config.sh` (`config::import_codex`) |
| `update-libraries.sh`            | Refresh `npm/global.json` (Dependabot owns package.json)                     | package.json                                    |
| `version.sh`                     | Semantic versioning                                                          | Makefile                                        |
| `update-agents-md.sh`            | AGENTS.md 自動生成セクション更新                                             | repo-maintenance                                |
| `repo-maintenance.sh`            | Repository maintenance executable workflow                                   | `/repo-maintenance`                             |
| `fleet-workflow-guards.sh`       | Workflow guards across every recently pushed repository                      | fleet-workflow-guards                           |
| `validate-takt-auth.sh`          | Fail fast on rejected Anthropic credentials                                  | scheduled-maintenance                           |
| `trust-claude-workspace.sh`      | Trust a workspace in `~/.claude.json` for headless runs                      | scheduled-maintenance                           |
| `setup-ci.sh`                    | CI/CD workflow setup                                                         | `/setup-ci`                                     |
| `setup-new-repo.sh`              | New repository bootstrap                                                     | `/setup-new-repo`                               |
| `audit-references.sh`            | Reports code/test/docs references to files under `script/` and `templates/`  | Manual maintenance                              |
| `macos/setup-bettertouchtool.js` | BetterTouchTool gesture setup for AeroSpace/Raycast                          | Local macOS setup                               |

## Configuration Management

### macos/setup-bettertouchtool.js

Adds the managed BetterTouchTool gesture entry points for the macOS desktop
setup. The script is append-only: it adds missing `CODEX-BTT-*` triggers and
preserves existing BetterTouchTool triggers.

**Usage**:

```bash
osascript -l JavaScript ./script/macos/setup-bettertouchtool.js
```

**Managed gestures**:

| Gesture                           | Action                             |
| --------------------------------- | ---------------------------------- |
| 3 finger swipe left/right         | AeroSpace workspace next/previous  |
| 3 finger swipe down               | `Cmd+W`                            |
| 3 finger tap                      | AeroSpace workspace back-and-forth |
| 3 finger click                    | Middle click                       |
| 4 finger swipe left/right/up/down | AeroSpace focus movement           |
| 4 finger tap                      | Open Raycast                       |

### codex-config-merge.py

Deploys the repository's shared `.codex/config.toml` onto the terminal's real
`~/.codex/config.toml` by deep-merging instead of symlinking. Codex/ChatGPT
apps write terminal-local state (trust levels, marketplace paths, plugin
enablement, absolute-path MCP definitions) directly into `config.toml`, so a
symlink to the tracked file left `git status` permanently dirty. See
[ADR 0022](../docs/adr/0022-codex-config-merge-deploy.md) for the full
rationale.

**Usage**:

```bash
./script/codex-config-merge.py <base_toml> <target_toml>
```

**Called by**: `config::deploy_codex_config` in `script/lib/config.sh`, invoked
from `config::import_codex` during `./script/import.sh`. Requires `uv`
(Python 3.11+); without it, `config::deploy_codex_config` falls back to
converting an existing symlink to a real file or seeding a copy, skipping the
merge.

**Merge rule**: tables merge recursively; base keys win over local keys;
local-only keys (terminal state) are preserved. Deleting a key from the base
does not propagate to already-deployed local files.

### export.sh

Exports configuration settings (Zsh dotfiles, etc.) to the home directory.

**Usage**: `./script/export.sh`

**Check mode**: `./script/export.sh --check`

### import.sh

Imports configuration settings from the home directory back to the repository.

**Usage**: `./script/import.sh`

**Check mode**: `./script/import.sh --check`

**Repository clone**: `./script/import.sh --with-repos` — GitHub の全リポジトリを ghq で一括クローンする（デフォルトはスキップ）

## Credential Management

### credentials.sh

Secure credential management using 1Password CLI integration.

**Usage**:

```bash
# Fetch all credentials from 1Password
./script/credentials.sh fetch

# Clean up generated credential files
./script/credentials.sh clean

# List available credential templates
./script/credentials.sh list
```

**Makefile targets**: `make credentials`, `make clean-credentials`, `make list-credentials`

### codespaces-secrets.sh

Manage GitHub Codespaces secrets across multiple repositories.

**Usage**:

```bash
./script/codespaces-secrets.sh list          # List all secrets
./script/codespaces-secrets.sh repos         # List configured repos
./script/codespaces-secrets.sh repos add owner/repo  # Add repo
./script/codespaces-secrets.sh diff          # Show sync status
./script/codespaces-secrets.sh sync          # Sync all secrets
./script/codespaces-secrets.sh init          # Initialize config
```

**Claude command**: `/codespaces-secrets`

## Claude Code Development

### setup-claude.sh

Initializes Claude Code CLI configuration, syncs settings, and installs plugins.

**Usage**: `./script/setup-claude.sh`

**Makefile target**: `make claude-setup`

**Note**: `link_private_skills` により、`keito4/private-config`（組織情報を含むスキルの正本）の
`.claude/skills/<name>.md` を `~/.claude/skills/<name>/SKILL.md` へ symlink する。
配置先は `PRIVATE_CONFIG_DIR` 環境変数で上書き可能（デフォルト:
`~/develop/github.com/keito4/private-config`）。

`~/.claude/settings.json` が既にある場合は端末固有設定を保持し、リポジトリ正本の
`permissions.allow` だけを重複排除しながら追加マージする。正本から削除した許可は
自動では削除されない。

### setup-claude-build.sh

Build-time setup for Claude Code in DevContainer images.

**Used by**: DevContainer Dockerfile

### install-claude-plugins.sh

Installs Claude Code plugins from the configured plugin list.

**Used by**: DevContainer build process

### install-skills.sh

Installs Claude Code skills from the configured skills list.

**Used by**: DevContainer postStartCommand

### restore-cli-auth.sh

Restores CLI authentication state (Claude, GitHub, etc.) from environment variables.

**Used by**: DevContainer postStartCommand

### update-claude-code.sh

Updates Claude Code CLI to the latest version.

**Usage**: `npm run update:claude` or `./script/update-claude-code.sh`

**Claude command**: `/update-claude-code`

### fix-mcp-token-exposure.sh

Rewrites MCP server definitions in `.claude.json` so that API tokens travel through the
environment instead of the command line. Tokens embedded in `argv` are readable by any
process of the same user via `ps`.

**Usage**:

```bash
./script/fix-mcp-token-exposure.sh                 # 既定スコープと ~/.claude-private を修正
./script/fix-mcp-token-exposure.sh --check         # 検査のみ (書き込みなし・claude CLI 不要)
./script/fix-mcp-token-exposure.sh --print linear  # 生成される定義を確認
```

**Managed servers**: `linear`, `supabase`, `sentry-elu`

**Notes**:

- 既定スコープの状態ファイルは `~/.claude/.claude.json` ではなく `~/.claude.json`（旧レイアウト）。
  `~/.claude/.claude.json` だけ直しても既定セッションには反映されない。
- MCP はセッション起動時に spawn されるため、反映には対象セッションの再起動が必要。
- `mcp-remote` は `--header` 値の `${VAR}` を `process.env` から展開する。ヘッダの解析は
  `^([A-Za-z0-9_-]+):\s*(.*)$` なので、コロン直後にスペースを置かない形式で渡す。

## Quality & CI Scripts

### repo-maintenance.sh

Runs repository maintenance checks and managed updates. This is the executable source of truth for `/repo-maintenance`.

**Usage**:

```bash
./script/repo-maintenance.sh --mode full
./script/repo-maintenance.sh --mode check-only
./script/repo-maintenance.sh --check-required-workflows
./script/repo-maintenance.sh --check-actions-pr-settings
./script/repo-maintenance.sh --check-scheduled-maintenance
./script/repo-maintenance.sh --check-artifact-retention
./script/repo-maintenance.sh --check-claude-action-credentials
./script/repo-maintenance.sh --check-self-cancelling-workflows
./script/repo-maintenance.sh --check-gh-repo-context
```

The workflow guards (`--check-claude-action-credentials`, `--check-self-cancelling-workflows`,
`--check-gh-repo-context`, `--check-artifact-retention`) scan `.github/workflows/`,
`.github/workflows/templates/`, and `templates/workflows/`. `ci.yml` runs all four in its
Workflow Lint job so regressions fail the pull request.

### fleet-workflow-guards.sh

Runs the repo-maintenance workflow guards across several repositories at once.
The guards only read workflow YAML, so they run unchanged against any checkout;
keeping them here means a fix to a guard reaches every repository on the next
run without distributing this script downstream.

The scan is read-only. It never opens issues or pull requests in the scanned
repositories.

**Usage**:

```bash
./script/fleet-workflow-guards.sh                       # 直近90日に push されたリポジトリ
./script/fleet-workflow-guards.sh --days 30
./script/fleet-workflow-guards.sh --repos "config ohana"
```

Requires `gh` authenticated with a token that can read the target repositories.
`.github/workflows/fleet-workflow-guards.yml` runs it weekly with `CLAUDE_PAT`
and writes the per-repository result to the job summary.

### setup-ci.sh

Detects project type and package manager, then writes CI/CD workflow defaults.

**Usage**:

```bash
./script/setup-ci.sh --dry-run
./script/setup-ci.sh --type nextjs --level standard
```

### setup-new-repo.sh

Bootstraps a repository with config-managed development defaults.

**Usage**:

```bash
./script/setup-new-repo.sh ../new-project --type nodejs
./script/setup-new-repo.sh ../new-project --minimal --no-install
```

### check-file-length.sh

Checks staged TS/JS files for excessive line counts.

**Usage**: `./script/check-file-length.sh`

**Behavior**:

| Line Count | Behavior                         |
| ---------- | -------------------------------- |
| ~349       | Pass (no output)                 |
| 350-499    | Warning displayed, commit passes |
| 500+       | Error, commit blocked            |

**Configuration**: Create `.filelengthignore` (same syntax as `.gitignore`) to exclude files.

**Template**: `.filelengthignore.template`

### pre-pr-checklist.sh

Runs pre-PR quality checklist before creating pull requests.

**Claude command**: `/pre-pr-checklist`

### security-credential-scan.sh

Scans codebase for accidentally committed credentials and secrets.

**Usage**: `./script/security-credential-scan.sh [--strict]`

**Claude command**: `/security-credential-scan`

### code-complexity-check.sh

Analyzes code complexity metrics (cyclomatic complexity, nesting depth, etc.).

**Usage**: `./script/code-complexity-check.sh [--threshold N] [--strict]`

**Claude command**: `/code-complexity-check`

### test-coverage-trend.sh

Tracks and reports test coverage trends over time.

**Usage**: `./script/test-coverage-trend.sh [--record]`

**Claude command**: `/test-coverage-trend`

### changelog-generator.sh

Generates changelog from conventional commits.

**Usage**: `./script/changelog-generator.sh --since <tag>`

**Claude command**: `/changelog-generator`

### audit-references.sh

Audits tracked files under `script/` and `templates/` and reports which
code/CI, test, and docs files reference each one. Useful for finding orphaned
scripts before deleting them or when checking whether a new script needs to be
wired into docs/CI.

**Usage**:

```bash
./script/audit-references.sh                  # Markdown report
./script/audit-references.sh --format tsv      # Machine-readable output
```

## Infrastructure & DevContainer

### version.sh

Semantic versioning helper for DevContainer releases.

**Usage**:

```bash
./script/version.sh --type patch  # Create patch version
./script/version.sh --type minor  # Create minor version
./script/version.sh --type major  # Create major version
./script/version.sh --dry-run     # Preview next version
```

**Makefile targets**: `make version-patch`, `make version-minor`, `make version-major`

### update-libraries.sh

Refreshes `npm/global.json` to the latest published versions via `npm view`. npm devDependencies (`package.json`) are managed by Dependabot — see [ADR 0006](../docs/adr/0006-consolidate-version-updates.md). Entries with `overridden: true` are pinned and skipped.

**Usage**: `npm run update:libs`

### brew-deps.sh

Homebrew dependency management and analysis.

**Usage**:

```bash
./script/brew-deps.sh leaves       # List packages without dependencies
./script/brew-deps.sh categorized  # List packages by category
./script/brew-deps.sh generate     # Generate standalone Brewfiles
./script/brew-deps.sh deps <pkg>   # Show dependencies of a package
./script/brew-deps.sh uses <pkg>   # Show packages depending on a package
```

**Makefile targets**: `make brew-leaves`, `make brew-categorized`, `make brew-generate`, etc.

### verify-container-setup.sh

Verifies that DevContainer setup completed successfully.

**Used by**: DevContainer validation

### container-health.sh

Comprehensive DevContainer health check.

**Usage**: `./script/container-health.sh [--json]`

**Claude command**: `/container-health`

### install-npm-globals.sh

Installs global npm packages defined in `npm/global.json`.
Uses npm's legacy peer dependency resolver for global CLI packages to match DevContainer builds.

**Used by**: DevContainer postCreateCommand

**Note**: npm prefix が読み取り専用の Nix store を指す環境（macOS の nix 管理 npm）ではスキップされる。CLI ツールは `nix/home/packages.nix` で管理する。

### create-codespace.sh

Creates a GitHub Codespace with configurable options.

**Usage**:

```bash
./script/create-codespace.sh                      # Default settings
./script/create-codespace.sh -b feature/branch    # Specific branch
./script/create-codespace.sh -m premiumLinux      # Larger machine
./script/create-codespace.sh -n "My Environment"  # Custom display name
./script/create-codespace.sh --dry-run            # Preview command
./script/create-codespace.sh -l                   # List machine sizes
```

**Options**:

| Option               | Description                 | Default                                    |
| -------------------- | --------------------------- | ------------------------------------------ |
| `-b, --branch`       | Branch name                 | Current branch                             |
| `-m, --machine`      | Machine size                | standardLinux32gb                          |
| `-r, --repo`         | Repository (owner/repo)     | Current repo                               |
| `-t, --idle-timeout` | Idle timeout                | 30m                                        |
| `-n, --name`         | Display name (max 48 chars) | -                                          |
| `-c, --devcontainer` | devcontainer.json path      | .devcontainer/codespaces/devcontainer.json |

**Machine sizes**: `basicLinux32gb`, `standardLinux32gb`, `premiumLinux`, `largePremiumLinux`

### update-agents-md.sh

Regenerates the auto-generated section of `AGENTS.md` from the current repository state.

**Usage**:

```bash
./script/update-agents-md.sh          # Update AGENTS.md
./script/update-agents-md.sh --check  # Check for diff only (exit 1 if diff exists)
```

**Used by**: `/repo-maintenance` command

## Git & GitHub

### branch-cleanup.sh

Cleans up merged and stale git branches.

**Usage**: `./script/branch-cleanup.sh [--merged-only] [--yes]`

**Claude command**: `/branch-cleanup`

### setup-team-protection.sh

Configures GitHub branch protection rules for team development.

**Auto-detection**: When run without `--branches`, the script automatically includes existing `pre-production` and `production` branches alongside `main`. Passing `--branches` explicitly disables this auto-detection.

**Branch-type defaults** (when `--uniform` is NOT set):

| Branch                      | enforce_admins | required_reviews | code_owner_reviews |
| --------------------------- | -------------- | ---------------- | ------------------ |
| main                        | false          | 0                | false              |
| pre-production / production | false          | 1                | true               |

**Usage**:

```bash
./script/setup-team-protection.sh                         # Current repo (auto-detects env branches)
./script/setup-team-protection.sh owner/repo              # Specific repo
./script/setup-team-protection.sh --interactive           # Interactive mode with confirmations
./script/setup-team-protection.sh --dry-run               # Preview changes without applying
./script/setup-team-protection.sh --reviewers 2           # Require 2 approving reviewers
./script/setup-team-protection.sh --enforce-admins        # Apply rules to administrators too
./script/setup-team-protection.sh --branches main,pre-production,production --create-branches
./script/setup-team-protection.sh --protection-level strict  # 2 reviewers, linear history, signed commits
./script/setup-team-protection.sh --merge-method squash   # squash | merge | rebase | all | none
./script/setup-team-protection.sh --uniform               # Identical settings for all branches
./script/setup-team-protection.sh --skip-status-checks    # Skip Quality Gate required check
```

**Claude command**: `/setup-team-protection`

### dependency-health-check.sh

Analyzes project dependencies for security vulnerabilities and updates.

**Usage**: `./script/dependency-health-check.sh [--strict]`

**Claude command**: `/dependency-health-check`

## Library Functions (lib/)

Shared library functions used by multiple scripts:

| File                 | Purpose                                                                        |
| -------------------- | ------------------------------------------------------------------------------ |
| `output.sh`          | Colored output utilities (print_info, print_success, etc.); requires bash 4.0+ |
| `config.sh`          | Configuration loading utilities                                                |
| `platform.sh`        | Platform detection (macOS, Linux, etc.)                                        |
| `devcontainer.sh`    | DevContainer-specific utilities                                                |
| `claude_plugins.sh`  | Claude plugin management utilities                                             |
| `project-detect.sh`  | Shared project type and package manager detection                              |
| `brew_categories.py` | Homebrew package categorization                                                |

## Credential Providers (credentials/providers/)

| Provider  | File    | Description                            |
| --------- | ------- | -------------------------------------- |
| 1Password | `op.sh` | Uses `op` CLI for credential injection |

## ShellCheck Coverage

The following scripts are excluded from ShellCheck due to Zsh-specific features:

- `import.sh`, `export.sh` (Zsh-only syntax)
- `credentials.sh` (dynamic credential providers)
- `brew-deps.sh` (dynamic Homebrew metadata)
- `codespaces-secrets.sh` (complex GitHub API interactions)

## See Also

- [Main README](../README.md)
- [Credentials Documentation](../credentials/README.md)
- [DevContainer Documentation](../.devcontainer/README.md)
- [Claude Commands](./.claude/commands/README.md)
