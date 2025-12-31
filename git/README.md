# Git Configuration Files

This directory contains Git-related configuration files and templates.

## Files

- `gitconfig`: Global Git configuration template
- `gitignore`: Global gitignore patterns
- `commitlint.config.js`: Commitlint configuration with international language support

## Commitlint Configuration

### Overview

The `commitlint.config.js` file provides a commitlint configuration that supports non-English commit messages while maintaining conventional commits standards.

### The Problem

By default, commitlint's `subject-case` rule fails when using non-Latin characters:

```bash
# Default commitlint fails on Japanese
feat: 新機能を追加
❌ subject may not be sentence-case, start-case, pascal-case, upper-case
```

### The Solution

This configuration disables the `subject-case` rule while keeping all other conventional commit rules:

```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [0], // 日本語対応のため無効化
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'scope-empty': [0],
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore', 'perf', 'ci', 'build', 'revert'],
    ],
  },
};
```

### Valid Commit Examples

With this configuration, all these commits are valid:

```bash
# Japanese
feat: 新機能を追加
fix: バグを修正
docs: ドキュメントを更新

# English
feat: add new authentication feature
fix: resolve memory leak in cache

# Chinese
feat: 添加新功能
fix: 修复缓存问题

# Korean
feat: 새로운 기능 추가
fix: 버그 수정
```

### Setup Guide

#### DevContainer (Automatic)

This repository's DevContainer automatically sets up commitlint with Japanese language support:

1. The configuration is copied from `git/commitlint.config.js` to the workspace root during container creation
2. Dependencies are installed via `npm ci`
3. Husky hooks are configured to use commitlint

No manual setup needed when using DevContainer!

#### Manual Setup

##### 1. Install Dependencies

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

##### 2. Copy Configuration

```bash
cp git/commitlint.config.js ./commitlint.config.js
```

#### 3. Integrate with Husky (Recommended)

```bash
# Install Husky
npm install --save-dev husky

# Initialize Husky
npx husky init

# Add commit-msg hook
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
chmod +x .husky/commit-msg
```

#### 4. Test It

```bash
# Test with a commit message
echo "feat: テスト機能を追加" | npx commitlint
# ✅ Should pass

echo "invalid commit message" | npx commitlint
# ❌ Should fail
```

### Use Cases

This configuration is ideal for:

- Japanese development teams
- Chinese development teams
- Korean development teams
- Multilingual teams
- Any team using non-Latin characters in commit messages

### Benefits

- **International Teams**: Supports non-English commit messages
- **Standards**: Maintains conventional commits format
- **CI Integration**: Works with Husky and GitHub Actions
- **Flexibility**: Teams can write in their preferred language
- **Quality**: Still enforces commit message structure

### What's Still Enforced

Even with `subject-case` disabled, the configuration still enforces:

- ✅ Valid commit type (feat, fix, docs, etc.)
- ✅ Non-empty subject
- ✅ Non-empty type
- ✅ Conventional commits format

### What's Not Enforced

- ❌ Subject case (sentence-case, start-case, pascal-case, upper-case)

This allows you to use any language or case style in your commit message subject.

## See Also

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Commitlint](https://commitlint.js.org/)
- [Husky](https://typicode.github.io/husky/)
