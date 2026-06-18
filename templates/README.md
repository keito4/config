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
| `quality-gate-fallback.yml` | CI パス保証（fallback）         | setup-team-protection 導入済み    |

### pre-commit（`pre-commit-config-*.yaml`）

| テンプレート                       | いつ使う                                                                     |
| ---------------------------------- | ---------------------------------------------------------------------------- |
| `pre-commit-config-base.yaml`      | **全プロジェクト**: gitleaks + 基本チェック                                  |
| `pre-commit-config-terraform.yaml` | **Terraform プロジェクト**: base + terraform fmt/validate/tflint             |
| `pre-commit-config-full.yaml`      | **IaC + ドキュメント管理**: terraform + shellcheck + markdownlint + yamllint |

### Husky フック（`husky/`）

| テンプレート     | いつ使う                                                                                 |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `husky/pre-push` | **全プロジェクト**: typecheck / build / test:ci / npm audit を push 前に実行（自動検出） |

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

#### ポリシー設定（`github/policies/`）

| テンプレート                 | 内容                                                             | 優先度 |
| ---------------------------- | ---------------------------------------------------------------- | ------ |
| `complexity-thresholds.json` | McCabe / 認知的複雑度・関数行数・ネスト深さ・ファイル行数の閾値  | 中     |
| `allowed-licenses.json`      | 許可ライセンス・禁止ライセンス・例外パッケージリスト             | 中     |
| `severity-definitions.md`    | セキュリティ SLA (Critical 24h / High 7d / Medium 30d / Low 90d) | 中     |

> **Note**: `repo-maintenance --mode full` で欠落時のみ追加（既存ファイルは上書きしない）。

### コードスタイル（Prettier / lint-staged）

| テンプレート                      | いつ使う                                             |
| --------------------------------- | ---------------------------------------------------- |
| `prettierrc-base.json`            | **標準**: printWidth 80、arrowParens "avoid"         |
| `prettierrc-wide.json`            | **ワイド**: printWidth 120、arrowParens "always"     |
| `prettierignore`                  | **全プロジェクト**: 共通の除外パターン               |
| `lintstagedrc-eslint.json`        | **ESLint + Prettier**: lint + format on staged files |
| `lintstagedrc-biome.json`         | **Biome**: check + format on staged files            |
| `lintstagedrc-prettier-only.json` | **Prettier のみ**: format on staged files            |

### ESLint（`eslint/`）

| テンプレート        | いつ使う                                                                       |
| ------------------- | ------------------------------------------------------------------------------ |
| `eslint.config.mjs` | **ESLint flat config**: TypeScript ESLint v8+ 対応、Next.js / 複雑度ルール付き |

> `devDependencies.eslint` が存在し、既存 `.eslintrc*` / `eslint.config.*` が不在の場合に `repo-maintenance` が自動適用。

### Biome / commitlint

| テンプレート           | いつ使う                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------ |
| `biome.json`           | **Biome 採用プロジェクト**: `@biomejs/biome` を使う場合                              |
| `commitlint.config.js` | **Conventional Commits**: `setup-husky` とセット運用。husky 未設定の場合も単独利用可 |

### テスト設定（`testing/`）

| テンプレート       | 対象                                                             |
| ------------------ | ---------------------------------------------------------------- |
| `testing/`         | Next.js テスト基盤（5レベル、21種類）                            |
| `vitest.config.ts` | **Vitest 採用プロジェクト**: jsdom + v8 coverage + 70% threshold |

> `devDependencies.vitest` が存在する場合に `repo-maintenance` が自動適用。

### その他

| テンプレート                 | 対象                                       |
| ---------------------------- | ------------------------------------------ |
| `editorconfig`               | エディタ間のスタイル統一                   |
| `setup-file-length-check.sh` | ファイル行数チェック導入用の配布スクリプト |

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

# 例: ファイル行数チェックを導入
./templates/setup-file-length-check.sh /path/to/project
```

## 配布

テンプレートは config-base Docker イメージに含まれ、`/usr/local/share/config-templates/` に配置されます。
DevContainer 環境では `repo-maintenance` がこのパスからテンプレートを自動コピーします。
