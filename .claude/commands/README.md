# Claude Automated Commands

This directory contains pre-configured commands that provide automated workflows for common development tasks. These commands can be invoked directly by Claude or triggered automatically based on repository events and context.

## Quick Reference

| カテゴリ              | コマンド                        | 説明                                         |
| --------------------- | ------------------------------- | -------------------------------------------- |
| **Maintenance**       | `/repo-maintenance`             | 包括的なリポジトリメンテナンス               |
| **Git Workflow**      | `/git-sync`                     | Git 同期とブランチ管理                       |
|                       | `/branch-cleanup`               | マージ済み・古いブランチのクリーンアップ     |
|                       | `/create-pr`                    | ベースブランチをマージして PR 作成           |
| **Code Analysis**     | `/similarity-analysis`          | コードの類似性分析と重複検出                 |
|                       | `/code-complexity-check`        | コード複雑度分析とリファクタリング候補の特定 |
| **Quality & Testing** | `/pre-pr-checklist`             | PR 作成前の品質チェック                      |
|                       | `/test-coverage-trend`          | テストカバレッジのトレンド追跡               |
| **Security**          | `/dependency-health-check`      | 依存関係の健全性分析                         |
|                       | `/security-credential-scan`     | ハードコードされた認証情報のスキャン         |
|                       | `/security-review`              | セキュリティレビューと改善提案               |
| **DevContainer**      | `/container-health`             | コンテナ環境の健全性確認                     |
|                       | `/devcontainer-checklist`       | DevContainer 再起動後の確認チェックリスト    |
|                       | `/config-base-sync-check`       | config-base イメージのバージョン確認         |
|                       | `/config-base-sync-update`      | DevContainer を最新に更新して PR 作成        |
| **Setup**             | `/setup-new-repo`               | 新規リポジトリのセットアップ                 |
|                       | `/setup-ci`                     | CI/CD ワークフローのセットアップ             |
|                       | `/setup-husky`                  | Git hooks (Husky) のセットアップ             |
|                       | `/setup-team-protection`        | GitHub リポジトリ保護ルールの設定            |
| **Codespaces**        | `/codespaces-secrets`           | Codespaces シークレットの管理                |
| **Config Sync**       | `/sync-settings`                | Claude/Codex 設定の同期                      |
|                       | `/config-contribution-discover` | 新機能の発見と取り込み                       |
| **Updates**           | `/update-claude-code`           | Claude Code の更新                           |
|                       | `/update-actions`               | GitHub Actions バージョンの更新              |
| **Documentation**     | `/changelog-generator`          | Conventional Commits から CHANGELOG を生成   |

## Available Commands

### Maintenance

#### `repo-maintenance.md`

**Purpose**: Comprehensive repository maintenance - run all health checks and updates
**Features**:

- Environment health checks (container, DevContainer version, Claude Code)
- CI/CD setup checks (team protection, Husky, pre-PR checklist)
- Repository cleanup (branches, git gc)
- New feature discovery from config repository

**Usage**:

```
/repo-maintenance                    # Full maintenance
/repo-maintenance --mode quick       # Quick check (no updates)
/repo-maintenance --mode check-only  # Read-only checks
/repo-maintenance --skip security    # Skip specific category
/repo-maintenance --create-pr        # Create PR for changes
```

**Modes**:

| Mode       | Description                        |
| ---------- | ---------------------------------- |
| full       | Run all updates and checks         |
| quick      | Important checks only (no updates) |
| check-only | Read-only status checks            |

### Git Workflow

#### `git-sync.md`

**Purpose**: Provides comprehensive Git synchronization and branch management workflows
**Features**:

- Branch synchronization with upstream
- Conflict resolution guidance
- Git workflow automation
- Repository state validation

### Code Analysis

#### `similarity-analysis.md`

**Purpose**: Analyze code similarity in the repository to detect duplicate functions and patterns
**Features**:

- AST-based code similarity detection (not just text matching)
- Configurable similarity threshold
- Detailed refactoring recommendations
- Support for TypeScript/JavaScript codebases

**Usage**:

```
/similarity-analysis
/similarity-analysis path=src threshold=0.9
```

#### `code-complexity-check.md`

**Purpose**: Analyze code complexity and identify refactoring candidates
**Features**:

- Cyclomatic complexity analysis
- Function length and nesting depth detection
- Complexity thresholds (low/medium/high/critical)
- Refactoring recommendations
- CI integration with strict mode

**Usage**:

```
/code-complexity-check
/code-complexity-check --threshold 15
/code-complexity-check --strict
```

### Quality & Testing

#### `pre-pr-checklist.md`

**Purpose**: Automate comprehensive checks before creating a pull request
**Features**:

- Sequential quality checks (lint, format, test, etc.)
- PR size estimation and labeling
- Linked issues verification
- Branch status validation
- Merge conflict detection

**Usage**:

```
/pre-pr-checklist
/pre-pr-checklist --skip-tests
/pre-pr-checklist --verbose
```

#### `test-coverage-trend.md`

**Purpose**: Track and visualize test coverage trends over time
**Features**:

- Historical coverage tracking
- Trend analysis with ASCII graphs
- Threshold alerts (70% coverage)
- Per-file coverage breakdown
- CSV export for external analysis

**Usage**:

```
/test-coverage-trend
/test-coverage-trend --days 30
/test-coverage-trend --graph
```

### Security

#### `dependency-health-check.md`

**Purpose**: Comprehensive dependency health analysis
**Features**:

- npm package updates detection
- Security vulnerability scanning (`npm audit`)
- Deprecated package identification
- License compliance checking
- Health score calculation

**Usage**:

```
/dependency-health-check
/dependency-health-check --strict
/dependency-health-check --json
```

#### `security-credential-scan.md`

**Purpose**: Scan repository for hardcoded credentials and secrets
**Features**:

- API key, token, and password detection
- Private key and certificate scanning
- .env file validation
- False positive reduction
- Auto-fix capabilities

**Usage**:

```
/security-credential-scan
/security-credential-scan --fix
/security-credential-scan --strict
```

### Development Environment

#### `setup-husky.md`

**Purpose**: Configures Husky Git hooks for automated code quality enforcement
**Features**:

- Pre-commit hook setup
- Commit message validation
- Code quality gate enforcement
- Development workflow integration

#### `setup-ci.md`

**Purpose**: Setup comprehensive CI/CD workflows for your repository
**Features**:

- Project type auto-detection (Next.js, Node.js, Terraform, Monorepo)
- Gap analysis comparing current vs recommended CI configuration
- Multi-level setup (minimal, standard, comprehensive)
- Security scanning, E2E tests, and Claude Code Review integration

**Usage**:

```
/setup-ci                           # Auto-detect and recommend
/setup-ci --type nextjs             # Specify project type
/setup-ci --level comprehensive     # Full CI/CD setup
/setup-ci --dry-run                 # Preview changes only
```

**Levels**:

| Level         | Features                                            |
| ------------- | --------------------------------------------------- |
| minimal       | Lint + Build                                        |
| standard      | Lint + Test + Build + Security Audit                |
| comprehensive | All + E2E + CodeQL + Claude Review + Scheduled Scan |

#### `container-health.md`

**Purpose**: Verify DevContainer environment health and configuration
**Features**:

- Tool availability verification
- Version checking (Node.js, npm, Claude Code)
- Configuration validation
- System resource monitoring
- Auto-fix capabilities

**Usage**:

```
/container-health
/container-health --fix
/container-health --verbose
```

#### `devcontainer-checklist.md`

**Purpose**: DevContainer 再起動後の確認チェックリスト
**Features**:

- Node.js/npm 環境の確認
- Git 設定の確認
- Docker 動作確認
- LSP (Language Server Protocol) 設定確認
- 環境変数とクレデンシャルの確認
- Codespaces 環境の確認

**Usage**:

```
/devcontainer-checklist
```

#### `config-base-sync-check.md`

**Purpose**: Check current and latest config-base image versions
**Features**:

- 現在の DevContainer イメージバージョン確認
- 最新リリースバージョンの取得
- バージョン差分の表示

**Usage**:

```
/config-base-sync-check
```

#### `config-base-sync-update.md`

**Purpose**: Update DevContainer to latest config-base image, sync recommended features, and create PR
**Features**:

- config-base イメージの最新バージョンへの更新
- プロジェクトタイプに基づいた推奨 features の自動追加
- Claude Code 動作に必要な設定の確保
- 重複 features の検出と報告
- GitHub PR の自動作成
- Codespaces シークレット同期のリマインダー

**Usage**:

```
/config-base-sync-update
/config-base-sync-update --version 1.60.0
```

#### `setup-new-repo.md`

**Purpose**: Setup new repository with DevContainer, CI/CD, and development tools from config template
**Features**:

- Git リポジトリの初期化
- DevContainer 設定のコピー
- GitHub Actions ワークフローの設定
- 開発ツール（ESLint, Prettier, Jest, Husky）の設定
- ドキュメント（README, CLAUDE.md, SECURITY.md）の作成
- Codespaces シークレット紐付けの案内

**Usage**:

```
/setup-new-repo /path/to/new-repo
/setup-new-repo /path/to/new-repo --minimal
/setup-new-repo /path/to/new-repo --no-devcontainer
/setup-new-repo /path/to/new-repo --license Apache-2.0
```

#### `codespaces-secrets.md`

**Purpose**: GitHub Codespaces のシークレットとリポジトリの紐付けを CLI で管理
**Features**:

- シークレット一覧と紐付けリポジトリの表示
- 管理対象リポジトリの追加・削除
- 設定ファイルのリポジトリを全シークレットに一括紐付け
- 設定と現在の状態の差分確認

**Usage**:

```
/codespaces-secrets list
/codespaces-secrets repos add owner/repo
/codespaces-secrets sync
/codespaces-secrets diff
```

### Repository Management

#### `branch-cleanup.md`

**Purpose**: Clean up merged and stale branches
**Features**:

- Merged branch detection and deletion
- Stale branch identification (30+ days)
- Protected branch exclusion
- Interactive confirmation
- Remote branch cleanup support

**Usage**:

```
/branch-cleanup
/branch-cleanup --dry-run
/branch-cleanup --remote
```

#### `changelog-generator.md`

**Purpose**: Generate CHANGELOG from Conventional Commits history
**Features**:

- Automatic commit grouping by type
- GitHub commit and PR links
- Breaking changes highlighting
- Version detection
- Keep a Changelog format

**Usage**:

```
/changelog-generator
/changelog-generator --since v1.0.0
/changelog-generator --contributors
```

#### `setup-team-protection.md`

**Purpose**: Setup GitHub repository protection rules for team development
**Features**:

- Branch protection (no direct push, required reviews)
- Required status checks (CI passing)
- Repository settings (squash merge, auto-delete branches)
- Security features (Dependabot, vulnerability alerts)
- Configurable reviewer count and enforcement

**Usage**:

```
/setup-team-protection
/setup-team-protection --reviewers 2
/setup-team-protection owner/repo --dry-run
```

#### `create-pr.md`

**Purpose**: Create PR with latest base branch changes merged
**Features**:

- ベースブランチの最新変更をマージ
- 競合がある場合は解決を支援
- PR の自動作成

**Usage**:

```
/create-pr
/create-pr --base main
```

### Configuration Sync

#### `sync-settings.md`

**Purpose**: Sync Claude & Codex settings from Elu-co-jp projects to DevContainer configuration
**Features**:

- Claude/Codex 設定ファイルの同期
- DevContainer 設定との統合
- プロジェクト間の設定統一

**Usage**:

```
/sync-settings
```

#### `config-contribution-discover.md`

**Purpose**: Discover useful features in current repository and create issues for config repository
**Features**:

- リポジトリ内の有用な機能の発見
- config リポジトリへの Issue 作成
- 新機能の取り込み提案

**Usage**:

```
/config-contribution-discover
```

### Code Review

#### `security-review.md`

**Purpose**: コードのセキュリティレビューと改善提案
**Features**:

- セキュリティ観点でのコードレビュー
- 10 個の改善案の提示
- OWASP Top 10 に基づく脆弱性チェック

**Usage**:

```
/security-review
/security-review path/to/file.ts
```

### Updates

#### `update-claude-code.md`

**Purpose**: Update Claude Code to the latest version
**Features**:

- npm/global.json の Claude Code バージョン更新
- Dockerfile のバージョン更新
- 最新バージョンの自動検出

**Usage**:

```
/update-claude-code
```

#### `update-actions.md`

**Purpose**: Update GitHub Actions to the latest versions
**Features**:

- `.github/workflows/` 配下の全ワークフローファイルをスキャン
- SemVer タグのアクションを最新バージョンに更新
- メジャータグ固定・SHA ピンニング・ブランチ固定はスキップ

**Usage**:

```
/update-actions
npm run update:actions
```

#### 一括更新 (`npm run update:all`)

全依存関係を一括更新するオーケストレーター:

```bash
npm run update:all                              # 全更新
npm run update:all -- --skip-libs               # Claude + Actions のみ
npm run update:all -- --skip-claude             # libs + Actions のみ
npm run update:all -- --skip-actions            # libs + Claude のみ
npm run update:all -- --skip-libs --skip-claude # Actions のみ
```

## Scripts Used by Commands

以下のスクリプトがコマンドから呼び出されます。詳細は [script/README.md](../../script/README.md) を参照してください。

| スクリプト                    | 使用するコマンド            | 説明                                     |
| ----------------------------- | --------------------------- | ---------------------------------------- |
| `branch-cleanup.sh`           | `/branch-cleanup`           | マージ済み・古いブランチのクリーンアップ |
| `changelog-generator.sh`      | `/changelog-generator`      | Conventional Commits から CHANGELOG 生成 |
| `code-complexity-check.sh`    | `/code-complexity-check`    | コード複雑度分析                         |
| `codespaces-secrets.sh`       | `/codespaces-secrets`       | Codespaces シークレット管理              |
| `container-health.sh`         | `/container-health`         | コンテナ環境の健全性確認                 |
| `dependency-health-check.sh`  | `/dependency-health-check`  | 依存関係の健全性分析                     |
| `pre-pr-checklist.sh`         | `/pre-pr-checklist`         | PR 作成前の品質チェック                  |
| `security-credential-scan.sh` | `/security-credential-scan` | 認証情報のスキャン                       |
| `setup-team-protection.sh`    | `/setup-team-protection`    | GitHub 保護ルールの設定                  |
| `test-coverage-trend.sh`      | `/test-coverage-trend`      | テストカバレッジのトレンド追跡           |
| `update-claude-code.sh`       | `/update-claude-code`       | Claude Code の更新                       |
| `update-actions.sh`           | `/update-actions`           | GitHub Actions バージョンの更新          |
| `update-all.sh`               | npm scripts                 | 全依存関係の一括更新                     |

### DevContainer・インフラ用スクリプト（コマンド経由では使用しない）

| スクリプト                  | 使用場所                  | 説明                                    |
| --------------------------- | ------------------------- | --------------------------------------- |
| `setup-claude.sh`           | DevContainer postCreate   | Claude Code CLI の初期設定              |
| `setup-claude-build.sh`     | DevContainer Dockerfile   | ビルド時の Claude Code セットアップ     |
| `setup-env.sh`              | DevContainer postCreate   | 環境変数のセットアップ                  |
| `setup-mcp.sh`              | DevContainer postCreate   | MCP 設定のセットアップ                  |
| `setup-lsp.sh`              | DevContainer postCreate   | LSP サーバーのセットアップ              |
| `install-npm-globals.sh`    | DevContainer postCreate   | グローバル npm パッケージのインストール |
| `install-skills.sh`         | DevContainer postStart    | Claude スキルのインストール             |
| `install-claude-plugins.sh` | DevContainer build        | Claude プラグインのインストール         |
| `restore-cli-auth.sh`       | DevContainer postStart    | CLI 認証状態の復元                      |
| `verify-container-setup.sh` | DevContainer validation   | セットアップ完了の検証                  |
| `fix-container-plugins.sh`  | DevContainer troubleshoot | プラグイン権限の修正                    |
| `create-codespace.sh`       | 手動実行                  | Codespace の作成                        |
| `credentials.sh`            | Makefile                  | 1Password 認証情報管理                  |
| `export.sh`                 | 手動実行                  | 設定ファイルのエクスポート              |
| `import.sh`                 | 手動実行                  | 設定ファイルのインポート                |
| `brew-deps.sh`              | Makefile                  | Homebrew 依存関係管理                   |
| `update-libraries.sh`       | npm scripts               | ライブラリの更新                        |
| `version.sh`                | Makefile                  | セマンティックバージョニング            |
| `check-docs-sync.sh`        | CI                        | ドキュメント同期の確認                  |

## Additional Commands

For a comprehensive set of automated development commands, see the `.codex/prompts/` directory which contains 11 specialized prompts for:

- **Security Analysis**: Next.js security checks, dependency scanning, configuration auditing
- **Code Refactoring**: Decoupling, deduplication, reorganization, simplification
- **Git Operations**: Advanced Git workflows and synchronization

## Command Usage

### Direct Invocation

Commands can be invoked directly in Claude interactions:

```
@claude run git-sync to synchronize the current branch
@claude execute setup-husky to configure Git hooks
```

For additional commands available in `.codex/prompts/`:

```
@claude use next-security-check for comprehensive security analysis
@claude run refactor:decouple to improve code organization
@claude execute next-security:deps-scan for dependency vulnerability scanning
```

### Automatic Triggers

Commands are automatically triggered by:

- **Repository Events**: Push, PR creation, issue updates
- **Quality Thresholds**: Coverage drops, lint failures, security issues
- **Time-based Triggers**: Scheduled maintenance, dependency updates
- **Context Patterns**: Specific file changes, error patterns, user actions

### Workflow Integration

Commands integrate with development workflows through:

- **GitHub Actions**: Automated execution in CI/CD pipelines
- **Git Hooks**: Pre-commit, pre-push, and post-merge execution
- **IDE Integration**: Direct invocation from development environments
- **Slack/Teams**: Notification-driven execution

## Command Configuration

### Global Settings

Command behavior is configured in:

- `.claude/settings.json`: Global command preferences and thresholds
- `.claude/CLAUDE.md`: Quality standards and workflow requirements
- Repository-specific overrides in individual command files

### Environment Variables

Commands support customization through environment variables:

- `CLAUDE_COVERAGE_THRESHOLD`: Test coverage requirements
- `CLAUDE_SECURITY_LEVEL`: Security analysis strictness
- `CLAUDE_CI_TIMEOUT`: CI operation timeout limits
- `CLAUDE_REVIEWER_COUNT`: Required reviewer count for PRs

### Quality Gates

Commands enforce quality standards through:

- **Coverage Requirements**: 70%+ line coverage for all repositories
- **Security Standards**: Critical vulnerability blocking
- **Performance Thresholds**: Response time and resource usage limits
- **Documentation Standards**: Completeness and consistency requirements

## Best Practices

### For Development Teams

#### Command Usage

- **Use specific commands** for targeted analysis and fixes
- **Combine commands** for comprehensive workflows
- **Monitor command results** and act on recommendations
- **Customize thresholds** based on project requirements

#### Integration Strategies

- **Incorporate in CI/CD** for automated quality assurance
- **Use in code reviews** for consistent feedback
- **Schedule regular maintenance** commands for proactive management
- **Train team members** on command capabilities and usage

### For Project Maintainers

#### Configuration Management

- **Set appropriate thresholds** for quality gates
- **Customize command behavior** for technology stack
- **Monitor command performance** and effectiveness
- **Update configurations** based on team feedback

#### Workflow Optimization

- **Identify bottlenecks** in development processes
- **Automate repetitive tasks** with command workflows
- **Measure improvement** in code quality and velocity
- **Refine triggers** based on usage patterns

## Advanced Usage

### Command Chaining

Commands can be chained for complex workflows:

```
@claude run quality-check followed by test-all, then create a PR if all pass
@claude execute issue-auto-resolve, update dependencies, and run security-review
```

### Conditional Execution

Commands support conditional execution based on context:

```
@claude run fix-ci only if tests are failing
@claude execute security-review if changes affect authentication code
@claude run check-coverage if new code was added
```

### Custom Workflows

Create custom workflows by combining commands:

```yaml
# Example: Release Preparation Workflow
- quality-check
- test-all
- check-coverage
- security-review
- update-deps
- pr (with release template)
```

## Monitoring and Analytics

### Command Performance

Monitor command effectiveness through:

- **Execution time** and resource usage
- **Success rates** and failure patterns
- **Code quality improvements** over time
- **Developer productivity** metrics

### Quality Trends

Track quality improvements through:

- **Coverage trend** analysis
- **Security vulnerability** reduction
- **CI/CD reliability** improvements
- **Issue resolution time** reduction

## Troubleshooting

### Command Failures

If commands fail or produce unexpected results:

1. **Check prerequisites** (dependencies, permissions, environment)
2. **Review configuration** (settings, thresholds, environment variables)
3. **Examine logs** for error messages and stack traces
4. **Test manually** with reduced scope or simplified inputs
5. **Update command definitions** if necessary

### Performance Issues

If commands are slow or timing out:

1. **Review scope** and reduce if necessary
2. **Check resource availability** (memory, CPU, network)
3. **Optimize thresholds** and filters
4. **Consider parallel execution** for independent operations
5. **Monitor API rate limits** and usage

### Integration Problems

If commands don't integrate properly with workflows:

1. **Verify trigger configurations** and event handling
2. **Check permissions** and access controls
3. **Review environment variables** and context passing
4. **Test isolated execution** before workflow integration
5. **Update integration configurations** as needed

For detailed configuration and customization options, see the main [CLAUDE.md](../CLAUDE.md) documentation.
