# Git Configuration Files

This directory contains Git-related configuration files.

## Files

- `gitconfig`: Global Git configuration template
- `gitignore`: Global gitignore patterns

## Commitlint Configuration

The canonical commitlint configuration for this repository is [../commitlint.config.js](../commitlint.config.js). New repositories should copy [../templates/commitlint.config.js](../templates/commitlint.config.js).

### Manual Setup

#### 1. Install Dependencies

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

#### 2. Copy Configuration

```bash
cp templates/commitlint.config.js ./commitlint.config.js
```

#### 3. Integrate with Husky

```bash
npm install --save-dev husky
npx husky init
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
chmod +x .husky/commit-msg
```

Even with `subject-case` disabled, the configuration still enforces:

- Valid commit type (feat, fix, docs, etc.)
- Non-empty subject
- Non-empty type
- Conventional commits format

### What's Not Enforced

- Subject case (sentence-case, start-case, pascal-case, upper-case)

This allows you to use any language or case style in your commit message subject.

## See Also

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Commitlint](https://commitlint.js.org/)
- [Husky](https://typicode.github.io/husky/)
