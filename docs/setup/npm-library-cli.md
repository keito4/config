# npm ライブラリ (CLI) セットアップガイド

## 現状サマリー

[docs/tool-catalog.md](../tool-catalog.md) セクション 4.1 および `notion_orm` リポジトリの実態調査に基づく。

- [x] TypeScript 5.9.2 + Jest 30 (ts-jest) でテスト環境構築済み
- [x] ESLint 9 設定あり（Flat Config `eslint.config.mjs`）
- [x] Prettier 3.6.2 設定あり (`.prettierrc.json`: singleQuote: false, printWidth: 100)
- [x] CI/CD ワークフロー（ci.yml: Node 18/20/22 マトリックス、Lint, Build, Size Check, Audit）
- [x] semantic-release 24 導入済み（changelog + git + npm + github プラグイン）
- [x] husky 9 導入済み（pre-commit: `pnpm run lint && pnpm run build`）
- [x] CodeQL 自動セキュリティ分析あり (codeql.yml: 週次スケジュール)
- [x] claude.yml ワークフローあり
- [ ] commitlint（未導入、husky の commit-msg hook なし）
- [ ] カバレッジ閾値 70%+（現在: branches 35%, functions 45%, lines 45%, statements 45%）
- [ ] CI に `format:check` ステップ（未追加）
- [ ] lint-staged（未導入、pre-commit で全ファイル lint を実行）
- [ ] CLAUDE.md（未作成）
- [ ] ESLint 設定の重複（`.eslintrc.js` と `eslint.config.mjs` が共存）

**現在の品質ゲート達成率: 中〜高（基盤は充実、閾値引き上げと設定整理が主な残課題）**

## セットアップ項目

### 優先度: 高

#### 1. commitlint 導入

**何を**: husky に commitlint を追加し、Conventional Commits を強制する。

**なぜ**: semantic-release が commit-analyzer プラグインでコミットメッセージを解析してバージョンを決定する。commitlint がないと `fix:` や `feat:` でないコミットが混入し、意図しないリリース漏れが発生する。

**参考**: `/setup-husky` コマンドで commitlint を含む構成を導入可能。

**手動で追加する場合**:

```bash
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

**設定ファイル** (`commitlint.config.js`):

```js
export default { extends: ['@commitlint/config-conventional'] };
```

**husky hook 追加**（既存の `.husky/pre-commit` はそのまま維持）:

```bash
echo 'pnpm commitlint --edit "$1"' > .husky/commit-msg
```

#### 2. カバレッジ閾値を 70% に引き上げ

**何を**: Jest のカバレッジ閾値を全プロジェクト共通基準の 70% に段階的に引き上げる。

**なぜ**: 現在の `jest.config.js` の設定:

```js
coverageThreshold: {
  global: {
    branches: 35,     // → 70 が目標
    functions: 45,    // → 70 が目標
    lines: 45,        // → 70 が目標
    statements: 45,   // → 70 が目標
  },
},
```

TDD ベースライン（70%）に対して 25-35% 不足。段階的に引き上げる。

**段階的アプローチ**:

1. `pnpm test:coverage` で現在の実カバレッジを確認
2. 各指標を +10% ずつ引き上げ（例: 45% → 55% → 65% → 70%）
3. テスト追加と並行して実施

#### 3. CI に `format:check` ステップ追加

**何を**: CI パイプライン（ci.yml）に Prettier のフォーマット検証ステップを追加する。

**なぜ**: `format:check` スクリプトは `package.json` に定義済みだが、CI では実行されていない。`prepublishOnly` では実行されるが、PR マージ前の検証にはならない。

**ci.yml に追加**:

```yaml
- name: Format check
  run: pnpm format:check
```

### 優先度: 中

#### 4. lint-staged 導入

**何を**: コミット時にステージされたファイルのみ lint/format を実行する。

**なぜ**: 現在の pre-commit hook は `pnpm run lint && pnpm run build` で全ファイルを対象にしており、コミット時間が長い。lint-staged で差分のみに最適化する。

```bash
pnpm add -D lint-staged
```

**設定例** (`.lintstagedrc`):

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml}": ["prettier --write"]
}
```

**`.husky/pre-commit` を更新**:

```bash
pnpm exec lint-staged
```

#### 5. CLAUDE.md 作成

**何を**: プロジェクト固有の開発コンテキストを CLAUDE.md に記載する。

**含めるべき内容**（実リポジトリの構成に基づく）:

- **用途**: Notion API の ORM + CLI ツール（`notion-orm` コマンド）
- **技術スタック**: TypeScript, @notionhq/client 4, commander 14, chalk 5
- **テスト戦略**: ts-jest, jest.setup.js で chalk ESM モック化
- **リリースフロー**: semantic-release（main ブランチ push → npm publish）
- **ビルド**: `tsc` → `dist/` (declaration 付き)
- **公開設定**: `bin.notion-orm`, `files: ["dist", "README.md", "LICENSE"]`

#### 6. ESLint 設定の重複解消

**何を**: `.eslintrc.js` と `eslint.config.mjs` の共存を解消し、Flat Config に統一する。

**なぜ**: ESLint 9 では Flat Config が標準。現在 `eslint.config.mjs` が存在しテスト・dist 除外等の設定が整っているため、`.eslintrc.js` を削除して統合する。

**手順**:

1. `.eslintrc.js` の内容を確認し、`eslint.config.mjs` に未反映のルールがないか検証
2. `tsconfig.eslint.json`（`.eslintrc.js` 用）の参照を確認
3. `.eslintrc.js` と不要な `tsconfig.eslint.json` を削除
4. `pnpm lint` で正常動作を確認

### 優先度: 低

#### 7. ベースイメージ更新（1.0.13 → latest）

**何を**: DevContainer のベースイメージを最新版に更新する。

**なぜ**: AI CLI ツールやセキュリティパッチが大幅に遅れている（1.0.13 → 1.58.0+）。

**参考**: `/config-base-sync-update` コマンドで更新 + PR 作成が可能。

## DevContainer 最適化

- **ベースイメージ**: `ghcr.io/keito4/config-base:1.0.13` → `ghcr.io/keito4/config-base:latest`
- **既存 Features**: `node(20)`, `gh` — ベースイメージに含まれるため、更新後に削除を検討
