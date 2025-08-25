# Git Sync Commands

## sync-main

mainブランチに戻って最新版をpullする

```bash
#!/bin/bash
set -e

echo "🔄 Syncing with main branch..."

# 現在のブランチを保存
CURRENT_BRANCH=$(git branch --show-current)

# 変更がある場合は確認
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "⚠️  Uncommitted changes detected!"
    echo "Please commit or stash your changes before syncing."
    exit 1
fi

# mainブランチに切り替え
echo "📦 Switching to main branch..."
git checkout main

# 最新の変更を取得
echo "⬇️  Pulling latest changes..."
git pull origin main

echo "✅ Successfully synced with main branch!"
echo "📊 Latest commits:"
git log --oneline -5
```

## sync-current

現在のブランチを最新のmainと同期する

```bash
#!/bin/bash
set -e

echo "🔄 Syncing current branch with latest main..."

# 現在のブランチを保存
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "📦 Already on main branch, pulling latest..."
    git pull origin main
else
    # 変更がある場合は確認
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "⚠️  Uncommitted changes detected!"
        echo "Please commit or stash your changes before syncing."
        exit 1
    fi

    echo "📦 Current branch: $CURRENT_BRANCH"

    # mainの最新を取得
    echo "⬇️  Fetching latest main..."
    git fetch origin main

    # 現在のブランチにmainをマージ
    echo "🔀 Merging latest main into $CURRENT_BRANCH..."
    git merge origin/main

    echo "✅ Successfully synced $CURRENT_BRANCH with main!"
fi

echo "📊 Latest commits:"
git log --oneline -5
```

## create-pr

現在のブランチからPRを作成する

```bash
#!/bin/bash
set -e

echo "🚀 Creating Pull Request..."

# 現在のブランチを確認
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "❌ Cannot create PR from main branch!"
    echo "Please create a feature branch first."
    exit 1
fi

# 変更がある場合はコミット
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "📝 Uncommitted changes detected."
    read -p "Do you want to commit them? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        read -p "Enter commit message: " COMMIT_MSG
        git commit -m "$COMMIT_MSG"
    else
        echo "⚠️  Please commit your changes before creating a PR."
        exit 1
    fi
fi

# ブランチをプッシュ
echo "⬆️  Pushing branch to remote..."
git push -u origin "$CURRENT_BRANCH"

# PRを作成
echo "📝 Creating PR..."
gh pr create --fill

echo "✅ Pull Request created successfully!"
```

## stash-and-sync

変更を一時保存してmainと同期

```bash
#!/bin/bash
set -e

echo "📦 Stashing changes and syncing with main..."

# 変更がある場合はstash
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "💾 Stashing current changes..."
    git stash push -m "Auto-stash before sync $(date +%Y%m%d-%H%M%S)"
    STASHED=true
else
    STASHED=false
fi

# 現在のブランチを保存
CURRENT_BRANCH=$(git branch --show-current)

# mainに切り替えて最新を取得
echo "📦 Switching to main..."
git checkout main
git pull origin main

# 元のブランチに戻る（mainでない場合）
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "🔄 Returning to $CURRENT_BRANCH..."
    git checkout "$CURRENT_BRANCH"

    # mainの変更をマージ
    echo "🔀 Merging latest main..."
    git merge main
fi

# stashした変更を戻す
if [ "$STASHED" = true ]; then
    echo "📤 Restoring stashed changes..."
    git stash pop
fi

echo "✅ Sync complete!"
echo "📊 Status:"
git status --short
```

## branch-status

現在のブランチの状態を確認

```bash
#!/bin/bash

echo "📊 Branch Status Report"
echo "======================="

# 現在のブランチ
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# リモートとの差分
echo ""
echo "🔄 Remote status:"
git fetch origin --quiet
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "no-remote")

if [ "$REMOTE" = "no-remote" ]; then
    echo "  ⚠️  No remote tracking branch"
else
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "  ✅ Up to date with remote"
    else
        BEHIND=$(git rev-list --count HEAD..@{u})
        AHEAD=$(git rev-list --count @{u}..HEAD)
        if [ "$BEHIND" -gt 0 ]; then
            echo "  ⬇️  Behind by $BEHIND commits"
        fi
        if [ "$AHEAD" -gt 0 ]; then
            echo "  ⬆️  Ahead by $AHEAD commits"
        fi
    fi
fi

# mainとの差分
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo ""
    echo "📈 Comparison with main:"
    git fetch origin main --quiet
    BEHIND_MAIN=$(git rev-list --count HEAD..origin/main)
    AHEAD_MAIN=$(git rev-list --count origin/main..HEAD)

    if [ "$BEHIND_MAIN" -gt 0 ]; then
        echo "  ⬇️  Behind main by $BEHIND_MAIN commits"
    fi
    if [ "$AHEAD_MAIN" -gt 0 ]; then
        echo "  ⬆️  Ahead of main by $AHEAD_MAIN commits"
    fi
    if [ "$BEHIND_MAIN" -eq 0 ] && [ "$AHEAD_MAIN" -eq 0 ]; then
        echo "  ✅ Even with main"
    fi
fi

# ローカルの変更
echo ""
echo "📝 Local changes:"
CHANGES=$(git status --porcelain | wc -l)
if [ "$CHANGES" -eq 0 ]; then
    echo "  ✅ Working directory clean"
else
    echo "  📄 Modified files: $(git diff --name-only | wc -l)"
    echo "  ➕ Staged files: $(git diff --cached --name-only | wc -l)"
    echo "  ❓ Untracked files: $(git ls-files --others --exclude-standard | wc -l)"
fi

# 最近のコミット
echo ""
echo "📜 Recent commits:"
git log --oneline -5
```
