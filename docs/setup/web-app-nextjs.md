# Web アプリ (Next.js) セットアップガイド

## 現状サマリー

[docs/tool-catalog.md](../tool-catalog.md) セクション 4.1 および `ohana` リポジトリ（`ohana-ops/`）の実態調査に基づく。

- [x] Next.js 15.5.7 + TypeScript 5.9.3 + React 19.2.0 構成済み
- [x] Jest 30 + Testing Library でユニットテスト環境あり
- [x] Playwright 1.55.1 で E2E テスト環境あり（CI は Chromium のみ）
- [x] ESLint Flat Config (`eslint.config.mjs`) + TypeScript ESLint 設定あり
- [x] Prettier 設定あり (`.prettierrc`)
- [x] CI/CD ワークフロー（typecheck → lint → test → build → e2e → security）
- [x] Vercel デプロイ（staging + production）
- [x] husky + commitlint 導入済み（pre-commit + pre-push + commit-msg）
- [x] lint-staged 導入済み（ESLint + Prettier）
- [x] Supabase SSR + Zod 4 + Tailwind CSS 4 + LangSmith 導入済み
- [x] Claude Code Review ワークフローあり
- [x] Supabase Vault drift/sync ワークフローあり
- [ ] カバレッジ閾値 70%+（現在: lines 8%, statements 8%, functions 35%, branches 60%）
- [ ] lint スクリプトの `--max-warnings 999` 解除
- [ ] CLAUDE.md（未作成）
- [ ] DevContainer 冗長 Features の削除

**現在の品質ゲート達成率: 高い（カバレッジ閾値と lint 厳格化が主な残課題）**

## セットアップ項目

### 優先度: 高

#### 1. カバレッジ閾値の段階的引き上げ

**何を**: Jest のカバレッジ閾値を全プロジェクト共通基準の 70% に段階的に引き上げる。

**なぜ**: 現在の `jest.config.js` の設定:

```js
coverageThreshold: {
  global: {
    lines: 8,        // → 70 が目標
    functions: 35,    // → 70 が目標
    branches: 60,     // → 70 が目標（最も近い）
    statements: 8,    // → 70 が目標
  },
},
```

lines/statements が 8% では事実上カバレッジチェックとして機能していない。

**段階的アプローチ**:

1. `npm run test:coverage` で現在の実カバレッジを計測
2. 各指標を現在値 + 10% ずつ引き上げ（branches は 60% → 70% を先行）
3. テスト追加と並行して閾値を段階的に引き上げ
4. 最終目標: 全指標 70%

**注意**: `collectCoverageFrom` で components/lib 配下のみ対象。supabase/migrations 等は除外済み。

#### 2. lint スクリプトの厳格化

**何を**: `package.json` の lint スクリプトから `--max-warnings 999` を削除し、`--max-warnings 0` に変更する。

**なぜ**: `--max-warnings 999` は事実上すべての warnings を許容しており、Static Quality Gates のルール（Error=Fail）の精神に反している。

**修正箇所**: `package.json`

```json
// Before
"lint": "next lint --max-warnings 999",
// After
"lint": "next lint --max-warnings 0",
```

**事前対応**: `npm run lint:strict`（既に `--max-warnings 0` で定義済み）を実行し、現在の warning 数を確認。必要に応じて先に warning を修正する。

### 優先度: 中

#### 3. CLAUDE.md 作成

**何を**: プロジェクト固有の開発コンテキストを CLAUDE.md に記載する。

**なぜ**: AI 支援開発の品質を一定に保つ。既に claude.yml と claude-code-review.yml が導入されているが、プロジェクトコンテキストがない。

**含めるべき内容**（実リポジトリの構成に基づく）:

- **技術スタック**: Next.js 15 (App Router), React 19, Supabase SSR, Tailwind CSS 4, Zod 4
- **AI 連携**: OpenAI, Anthropic SDK, Google Generative AI, LangSmith
- **外部サービス**: Supabase (Auth/DB/Storage), Notion API, Google APIs
- **テスト戦略**: Jest + Testing Library (Unit), Playwright (E2E, CI は Chromium のみ)
- **デプロイ**: Vercel (staging → production)
- **品質ゲート**: pre-commit (lint-staged) → pre-push (typecheck + lint + format + test)

### 優先度: 低

#### 4. DevContainer 冗長 Features の削除

**何を**: ベースイメージに含まれるツールと重複する Features を `devcontainer.json` から削除する。

**なぜ**: ビルド時間の短縮とバージョン競合リスクの排除。

**現在の Features**（7 項目）:

```json
"features": {
  "ghcr.io/devcontainers/features/git:1": {},           // ベースイメージに含まれる
  "ghcr.io/devcontainers-extra/features/pnpm:2": {},     // ベースイメージに含まれる
  "ghcr.io/devcontainers/features/github-cli:1": {},     // ベースイメージに含まれる
  "ghcr.io/eitsupi/devcontainer-features/jq-likes:2": {},// ベースイメージに含まれる
  "ghcr.io/devcontainers-extra/features/supabase-cli":{},// ベースイメージに含まれる
  "ghcr.io/devcontainers/features/docker-in-docker:2":{},// 維持（プロジェクト固有）
  "ghcr.io/schlich/devcontainer-features/playwright:0":{}// 維持（E2E テスト用）
}
```

**削除候補**: git, pnpm, github-cli, jq-likes, supabase-cli（5 項目）
**残すべき Features**: docker-in-docker, playwright

#### 5. ベースイメージ更新（1.54.0 → latest）

**何を**: DevContainer のベースイメージを最新版に更新する。

**なぜ**: 最新の AI CLI ツールやセキュリティパッチを適用する。

**参考**: `/config-base-sync-update` コマンドで更新 + PR 作成が可能。

## DevContainer 最適化

- **ベースイメージ**: `ghcr.io/keito4/config-base:1.54.0` → `ghcr.io/keito4/config-base:latest`
- **削除対象 Features**: ベースイメージと重複する 5 項目（git, pnpm, github-cli, jq-likes, supabase-cli）
- **残すべき Features**: `docker-in-docker`, `playwright` — プロジェクト固有の要件
