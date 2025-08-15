# How to Create a Pull Request Using GitHub CLI

This command helps you create pull requests following our development standards and quality gates.

**Important**: All PR titles and descriptions should be written in English.

## Prerequisites

1. Install GitHub CLI if you haven't already:

   ```bash
   # macOS
   brew install gh

   # Windows
   winget install --id GitHub.cli

   # Linux
   # Follow instructions at https://github.com/cli/cli/blob/trunk/docs/install_linux.md
   ```

2. Authenticate with GitHub:
   ```bash
   gh auth login
   ```

## Creating a New Pull Request

### Pre-PR Checklist

1. **Branch Verification**

   ```bash
   # Check branch name follows convention: feat|fix|chore/<issue#>-slug
   git branch --show-current
   ```

2. **Change Size Verification**

   ```bash
   # Verify file count ≤ 25
   git diff --name-only origin/main | wc -l

   # Verify diff ≤ 400 lines per file
   git diff --shortstat origin/main
   git diff --stat origin/main
   ```

3. **Quality Gates**
   ```bash
   # Run all tests and quality checks
   npm run test:all
   npm run quality:check
   pnpm lint
   pnpm build
   pnpm generate:docs
   ```

### Creating the PR

1. **Prepare PR Description**

   Follow the template in `.github/pull_request_template.md`

2. **Create Draft PR**

   ```bash
   # Basic command structure
   gh pr create --draft --title "✨(scope): Your descriptive title" --body "Your PR description" --base main
   ```

   For complex PR descriptions with proper formatting:

   ```bash
   # Create PR with template structure
   gh pr create --draft --title "✨(scope): Your descriptive title" --body-file .github/pull_request_template.md --base main
   ```

### PR Review Process

After committing, perform comprehensive code review using these specialized agents:

- **accessibility-design-validator** - WCAG compliance, design consistency
- **concurrency-safety-analyzer** - Thread safety, async patterns
- **ddd-architecture-validator** - Domain architecture compliance
- **docs-consistency-checker** - Documentation completeness
- **nuget-dependency-auditor** - Dependency security and licensing
- **performance-analyzer** - Performance implications
- **testability-coverage-analyzer** - Test coverage and quality

### Security Considerations

- Use `git add` file by file, not `git add .`
- Review each file for sensitive information before staging
- Never commit secrets, keys, or confidential data

## Best Practices

### PR Title Format

Use conventional commit format with emojis:

- Always include an appropriate emoji at the beginning
- Use actual emoji characters (not codes like `:sparkles:`)
- Examples:
  - `✨(supabase): Add staging remote configuration`
  - `🐛(auth): Fix login redirect issue`
  - `📝(readme): Update installation instructions`

### Branch Management

- If on main branch, create new branch before committing
- Follow naming convention: `feat|fix|chore/<issue#>-slug`

### Description Template

Always use our PR template structure from `.github/pull_request_template.md`:

- Keep all section headers exactly as they appear
- Don't add custom sections
- Include all template sections (mark as "N/A" if not applicable)

### Draft vs Ready

- Start as draft when work is in progress (`--draft` flag)
- Convert to ready for review when complete: `gh pr ready`

## Size Guidelines

### Acceptable Limits

- ✅ File count ≤ 25
- ✅ Each file diff ≤ 400 lines
- ✅ Linked Issue required
- ✅ All tests green
- ✅ Quality gates pass

### When Changes Are Too Large

1. Split functionality into multiple PRs
2. Separate refactoring from feature additions
3. Break large files into smaller modules

## Additional GitHub CLI PR Commands

```bash
# List your open pull requests
gh pr list --author "@me"

# Check PR status
gh pr status

# View a specific PR
gh pr view <PR-NUMBER>

# Check out a PR branch locally
gh pr checkout <PR-NUMBER>

# Convert draft to ready for review
gh pr ready <PR-NUMBER>

# Add reviewers
gh pr edit <PR-NUMBER> --add-reviewer username1,username2

# Merge PR
gh pr merge <PR-NUMBER> --squash
```

## Troubleshooting

### When Changes Are Too Large

1. Split features into multiple PRs
2. Separate refactoring from new features
3. Break large files into smaller modules

### When Issue Isn't Linked

1. Create issue: `gh issue create`
2. Add `Closes #<issue-number>` to PR title/body

### When Tests Fail

1. Run `npm run test:all` for details
2. Fix failing tests
3. Add missing tests if needed

### When Quality Gates Fail

1. Fix linting: `npm run lint -- --fix`
2. Fix vulnerabilities: `npm audit fix`
3. Update documentation as needed

## Success Criteria

- ✅ File count ≤ 25
- ✅ Each file diff ≤ 400 lines
- ✅ Issue linked
- ✅ All tests green
- ✅ Quality gates pass
- ✅ All 7 specialized agents approve
- ✅ PR created successfully

## Related Documentation

- [PR Template](.github/pull_request_template.md)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI documentation](https://cli.github.com/manual/)
