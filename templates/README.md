# Templates

プロジェクト初期化と `repo-maintenance` で自動適用されるテンプレート集です。

## テンプレート選択ガイド

### ワークフロー（`workflows/`）

| テンプレート                | 対象                            | 自動適用条件                      |
| --------------------------- | ------------------------------- | --------------------------------- |
| `dependabot-auto-merge.yml` | Dependabot を使う全プロジェクト | dependabot.yml が存在する場合     |
| `label-sync.yml`            | 全プロジェクト                  | 常に推奨                          |
| `stale.yml`                 | Issue/PR が多いプロジェクト     | 常に推奨                          |
| `terraform-drift.yml`       | Terraform プロジェクト          | Terraform ファイルが存在する場合  |
| `e2e-playwright.yml`        | Playwright E2E テスト           | test:e2e スクリプトが存在する場合 |
| `claude.yml`                | Claude Code 連携                | 常に推奨                          |

### pre-commit（`pre-commit-config-*.yaml`）

| テンプレート                       | いつ使う                                                                     |
| ---------------------------------- | ---------------------------------------------------------------------------- |
| `pre-commit-config-base.yaml`      | **全プロジェクト**: gitleaks + 基本チェック                                  |
| `pre-commit-config-terraform.yaml` | **Terraform プロジェクト**: base + terraform fmt/validate/tflint             |
| `pre-commit-config-full.yaml`      | **IaC + ドキュメント管理**: terraform + shellcheck + markdownlint + yamllint |

### GitHub 設定（`github/`）

| テンプレート               | 対象                                             | 優先度 |
| -------------------------- | ------------------------------------------------ | ------ |
| `dependabot.yml`           | npm/Actions/Docker/Terraform の依存更新          | 高     |
| `renovate.json`            | Renovate を使う場合（Dependabot と択一）         | 高     |
| `labels.yml`               | 標準ラベル定義（label-sync と組合せ）            | 高     |
| `pull_request_template.md` | PR の品質統一                                    | 高     |
| `ISSUE_TEMPLATE/`          | Issue の品質統一（bug_report + feature_request） | 中     |
| `CODEOWNERS`               | チーム開発でのレビュー自動アサイン               | 中     |
| `SECURITY.md`              | セキュリティポリシー                             | 中     |
| `CONTRIBUTING.md`          | コントリビューションガイド                       | 低     |

### コードスタイル（Prettier / lint-staged）

| テンプレート                      | いつ使う                                             |
| --------------------------------- | ---------------------------------------------------- |
| `prettierrc-base.json`            | **標準**: printWidth 80、arrowParens "avoid"         |
| `prettierrc-wide.json`            | **ワイド**: printWidth 120、arrowParens "always"     |
| `prettierignore`                  | **全プロジェクト**: 共通の除外パターン               |
| `lintstagedrc-eslint.json`        | **ESLint + Prettier**: lint + format on staged files |
| `lintstagedrc-biome.json`         | **Biome**: check + format on staged files            |
| `lintstagedrc-prettier-only.json` | **Prettier のみ**: format on staged files            |

### Git Hooks（`husky/`）

| テンプレート | 内容                                                |
| ------------ | --------------------------------------------------- |
| `pre-commit` | lint-staged + ファイル長チェック                    |
| `commit-msg` | commitlint（Conventional Commits）                  |
| `pre-push`   | typecheck + lint + test（スクリプト存在時のみ実行） |

### その他

| テンプレート   | 対象                                  |
| -------------- | ------------------------------------- |
| `editorconfig` | エディタ間のスタイル統一              |
| `testing/`     | Next.js テスト基盤（5レベル、21種類） |

## 使い方

### 自動適用（推奨）

```bash
# repo-maintenance が自動的にテンプレートを検出・適用
/repo-maintenance --mode full
```

### 手動コピー

```bash
# 例: PR テンプレートを追加
cp templates/github/pull_request_template.md .github/

# 例: pre-commit を追加（プロジェクト種別に応じて選択）
cp templates/pre-commit-config-base.yaml .pre-commit-config.yaml
pip install pre-commit && pre-commit install
```

## 配布

テンプレートは config-base Docker イメージに含まれ、`/usr/local/share/config-templates/` に配置されます。
DevContainer 環境では `repo-maintenance` がこのパスからテンプレートを自動コピーします。
