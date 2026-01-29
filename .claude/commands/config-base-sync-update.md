---
description: Update DevContainer to latest config-base image, sync recommended features, and create PR
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(curl:*), Bash(jq:*), Bash(find:*), Bash(test:*), Bash(ls:*), Bash(sed:*), Bash(grep:*), Bash(cat:*), Bash(echo:*), Bash(mkdir:*), Bash(rm:*), Bash(mv:*), Bash(cp:*), Bash(date:*)
argument-hint: [--version X.Y.Z]
---

# DevContainer Update Workflow

このコマンドは以下を自動実行します：

- config-baseイメージの最新バージョンへの更新
- プロジェクトタイプに基づいた推奨featuresの自動追加
- Claude Code動作に必要な設定の確保（mounts, postCreateCommand）
- 重複featuresの検出と報告
- GitHub PRの自動作成

## Step 1: Load Settings

Try to read `.claude/config-base-sync.local.md` for user configuration.

If the file exists:

- Extract `baseBranch`, `autoCreatePR`, `updateScope` from YAML frontmatter
- Validate settings values (baseBranch must be valid git branch, autoCreatePR must be boolean, updateScope must be one of: all, image-only, minimal)
- If validation fails, stop and report the error to the user

If the file does not exist or cannot be read:

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

### 4.1: Check if only devcontainer.json is modified

Check if the only modified file is `.devcontainer/devcontainer.json`:

```bash
MODIFIED_FILES=$(git status --porcelain | awk '{print $2}')
```

If only `.devcontainer/devcontainer.json` is modified:

### 4.2: Check if change is version-only

Analyze the diff to determine if it's only an image version change:

```bash
git diff .devcontainer/devcontainer.json
```

Check if:

1. The only change is in the `"image"` field
2. The change is a version number update (e.g., `ghcr.io/keito4/config-base:1.13.1` → `ghcr.io/keito4/config-base:1.15.0`)
3. No other fields are modified

**Detection logic**:

- Count the number of changed lines (excluding +/- prefixes)
- Verify all changes match the pattern: `"image": "ghcr.io/keito4/config-base:X.Y.Z"`
- Ensure both old and new versions point to the same registry and repository

If the change is **version-only**:

- Report: "✅ Detected version-only change in devcontainer.json (auto-overwrite enabled)"
- Show the version change: `X.Y.Z → target-version`
- Automatically discard the change and continue:
  ```bash
  git restore .devcontainer/devcontainer.json
  ```
- Proceed to Step 5

If the change includes **other modifications** (e.g., features, mounts, settings):

- Report error: "❌ Uncommitted changes detected in .devcontainer/devcontainer.json"
- Show the non-version changes
- Suggest: "Please commit or stash these changes before updating"
- Stop execution

### 4.3: Handle other uncommitted files

If there are uncommitted changes in **other files** (not just devcontainer.json):

- Report error: "Uncommitted changes detected. Please commit or stash changes before updating."
- List the uncommitted files
- Suggested actions:
  1. Review the changes: `git diff <file>`
  2. Commit the changes: `git add <file> && git commit -m "your message"`
  3. Or stash the changes: `git stash`
  4. Then re-run this command
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

## Step 6: Read Template and Recommended Configuration

Read the reference configuration from this repository:

- Read `/Users/keito4/develop/github.com/keito4/config/.devcontainer/devcontainer.json`
- Read `/Users/keito4/develop/github.com/keito4/config/.devcontainer/codex-config.json`
- Read `/Users/keito4/develop/github.com/keito4/config/.devcontainer/claude-settings.json`
- Read `/Users/keito4/develop/github.com/keito4/config/.claude/devcontainer-recommendations.md`

Extract recommended configuration based on `updateScope`:

- **all**: Update image, features, mounts, postCreateCommand, customizations
- **image-only**: Update only the image field
- **minimal**: Update image and features only

### Recommended Features Detection

From `devcontainer-recommendations.md`, identify:

1. **必須Features（全プロジェクト共通）**:
   - `ghcr.io/devcontainers/features/github-cli:1`
   - `ghcr.io/devcontainers/features/docker-in-docker:2`
   - `ghcr.io/devcontainers/features/git:1`

2. **Claude Code必須設定**:
   - `.codex` mount (必須)
   - `postCreateCommand`に`/usr/local/bin/setup-claude.sh`を含める

3. **プロジェクトタイプ別Features**（現在のプロジェクトに基づいて判定）:
   - Node.js/TypeScriptプロジェクト（package.jsonが存在）:
     - `ghcr.io/devcontainers/features/node:1`
     - `ghcr.io/devcontainers-extra/features/pnpm:2`
     - `ghcr.io/eitsupi/devcontainer-features/jq-likes:2`
   - Supabaseプロジェクト（supabase/config.tomlが存在）:
     - `ghcr.io/devcontainers-extra/features/supabase-cli`
   - E2Eテスト（playwright.config.tsが存在）:
     - `ghcr.io/schlich/devcontainer-features/playwright:0`
   - Terraformプロジェクト（\*.tfファイルが存在）:
     - `ghcr.io/devcontainers/features/terraform:1`

## Step 7: Update devcontainer.json

Based on `updateScope`, update `.devcontainer/devcontainer.json`:

### 7.1: Update Image Version

Update `image` field to `ghcr.io/keito4/config-base:{target-version}`

### 7.2: Update Features (if updateScope is "all" or "minimal")

**Features Update Strategy**:

1. **必須Features追加**（存在しない場合のみ追加）:
   - GitHub CLI
   - Docker-in-Docker
   - Git

2. **プロジェクトタイプ別Features追加**:
   - プロジェクト内のファイル存在をチェック
   - 該当するfeaturesを自動追加（存在しない場合のみ）

3. **既存Features保持**:
   - ユーザーが手動追加したfeaturesは保持
   - 推奨設定に含まれるfeaturesのバージョン設定を更新

4. **非推奨Features検出**:
   - config-baseに既に含まれるfeaturesを検出
   - ユーザーに削除推奨として報告（自動削除はしない）

**Features更新の報告**:

- ✅ 追加されるfeatures: [リスト]
- 📝 更新されるfeatures: [リスト]
- ⚠️ 削除推奨features: [リスト]（重複）
- ✨ 保持されるユーザー追加features: [リスト]

### 7.3: Update Mounts (if updateScope is "all")

**Claude Code必須mounts**を確認・追加:

- `.codex` mount

**標準mounts**を確認・追加:

- `.cursor` mount
- `.gitconfig` mount
- `.config/gh` mount

**環境変数ファイル設定（推奨）**:

- `.devcontainer.env`ファイルのマウントを追加:
  ```json
  "source=${localEnv:HOME}/.devcontainer.env,target=/home/vscode/.devcontainer.env,type=bind,consistency=cached"
  ```
- `containerEnv`に`CLAUDE_ENV_FILE`を追加:
  ```json
  "containerEnv": {
    "CLAUDE_ENV_FILE": "/home/vscode/.devcontainer.env"
  }
  ```
- この設定により、`setup-claude.sh`実行時に環境変数ファイルが読み込まれる
- ユーザーは`~/.devcontainer.env`ファイルを作成して環境変数を設定

既存のユーザー追加mountsは保持。

### 7.4: Update postCreateCommand (if updateScope is "all")

**Claude Code必須**:

- `postCreateCommand`に`/usr/local/bin/setup-claude.sh`が含まれているか確認
- 含まれていない場合は末尾に追加:
  ```
  既存コマンド && /usr/local/bin/setup-claude.sh
  ```

### 7.5: Update Other Settings (if updateScope is "all")

- Update `customizations` with recommended VS Code settings

Use the Edit tool to make precise updates to the JSON file.

## Step 8: Update Additional Config Files

If `updateScope` is "all":

- Check if `.devcontainer/codex-config.json` exists locally
  - If yes, compare with template and suggest updates if needed
- Check if `.devcontainer/claude-settings.json` exists locally
  - If yes, compare with template and suggest updates if needed

## Step 9: Report Changes

Display a detailed summary of all changes made:

### Image Version

- `ghcr.io/keito4/config-base:{old-version}` → `v{target-version}`

### Features Changes (if updateScope is "all" or "minimal")

**✅ 追加されたFeatures**:

```
- feature-name-1: version
- feature-name-2: version
```

**📝 更新されたFeatures**:

```
- feature-name: old-version → new-version
```

**⚠️ 削除推奨Features** (config-baseに含まれるため重複):

```
- feature-name-1
- feature-name-2
```

_注意: これらのfeaturesは自動削除されていません。必要に応じて手動で削除してください。_

**✨ 保持されたユーザー追加Features**:

```
- custom-feature-1: version
- custom-feature-2: version
```

### Mounts Changes (if updateScope is "all")

**追加されたMounts**:

- `.codex` (Claude Code必須)

### Commands Changes (if updateScope is "all")

**postCreateCommand**:

- 追加: `/usr/local/bin/setup-claude.sh` (Claude Code必須)

### Other Changes (if updateScope is "all")

- Updated VS Code customizations

## Step 10: Commit Changes

Create commit with conventional commit message including features details:

```bash
git add .devcontainer/
git commit -m "feat: Update config-base image to v{target-version}

- Update DevContainer image from v{old-version} to v{target-version}
- Sync configuration with latest recommended settings
- Add {count} new features based on project type detection
- Ensure Claude Code compatibility (mounts, postCreateCommand)
- Update features and mounts

Features added: {list-of-added-features}

Release notes: https://github.com/keito4/config/releases/tag/v{target-version}"
```

_Note: Replace `{count}` and `{list-of-added-features}` with actual values from Step 9._

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

  Updates DevContainer configuration to use the latest config-base image and syncs with recommended settings.

  ### Changes

  #### Image Version
  - **Image**: ghcr.io/keito4/config-base:{old-version} → v{target-version}

  #### Features
  - ✅ **Added**: {added-features-list}
  - 📝 **Updated**: {updated-features-list}
  - ⚠️ **Recommended for removal** (duplicates): {duplicate-features-list}
  - ✨ **Preserved**: {preserved-features-list}

  #### Configuration
  - 📁 **Mounts**: Added Claude Code required mounts (`.codex`)
  - 🔧 **postCreateCommand**: Ensured `/usr/local/bin/setup-claude.sh` execution
  - ⚙️ **Settings**: Synced VS Code customizations
  - 🔑 **containerEnv**: Added CLAUDE_ENV_FILE for environment configuration

  ### Claude Code Compatibility
  This update ensures full Claude Code compatibility with:
  - Required mounts for `.codex`
  - Automatic Claude CLI setup via `setup-claude.sh`
  - Recommended features based on project type

  ### Release Notes
  See: https://github.com/keito4/config/releases/tag/v{target-version}

  ### Testing Checklist
  - [ ] DevContainer builds successfully
  - [ ] Claude Code works (can run claude commands)
  - [ ] All project-specific tools work as expected
  - [ ] CI passes
  - [ ] No permission issues with mounts

  ### Recommended Actions
  {if duplicate-features exist}
  - Consider removing duplicate features: {duplicate-features-list}
  {endif}

  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  "
  ```

- Report PR URL to user

If `autoCreatePR` is false:

- Report: "Branch pushed successfully. Create PR manually with:"
- Show gh pr create command for user to run

## Step 12: Final Report

Provide a complete summary including features changes:

```
✅ DevContainer update complete!

📦 Image Version
- ghcr.io/keito4/config-base:{old-version} → v{target-version}

🔧 Features Summary
- Added: {count} features
- Updated: {count} features
- Recommended for removal: {count} features (duplicates)
- Preserved: {count} custom features

📁 Configuration
- Claude Code mounts: ✅ Configured
- setup-claude.sh: ✅ Included in postCreateCommand
- Standard mounts: ✅ Updated

🌿 Git Branch
- Branch: update-config-base-{target-version}
- PR: {PR-URL or "Manual creation required"}

📋 Next Steps
1. Review the pull request (check features changes)
2. Test the DevContainer locally:
   - Rebuild container: Cmd/Ctrl + Shift + P → "Dev Containers: Rebuild Container"
   - Verify Claude Code works: `claude --version`
   - Check all tools are available
3. {if duplicate features exist}
   Consider removing duplicate features before merging
   {endif}
4. Merge when all checks pass

💡 Tips
- Run `claude help` to verify Claude Code is working
- Check logs if container build fails
- Review `.devcontainer/devcontainer.json` for any conflicts
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
