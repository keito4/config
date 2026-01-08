# Git Configuration Files

This directory contains Git-related configuration files and templates.

## Files

- `gitconfig`: Global Git configuration template
- `gitignore`: Global gitignore patterns

## Usage

### gitconfig

This is a template for global Git configuration. Copy it to your home directory and customize as needed:

```bash
cp git/gitconfig ~/.gitconfig
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### gitignore

Global gitignore patterns that apply across all repositories. To use:

```bash
cp git/gitignore ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

## See Also

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Configuration Documentation](https://git-scm.com/docs/git-config)
