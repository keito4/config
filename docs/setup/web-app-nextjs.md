# Web アプリ (Next.js) セットアップガイド

## 対象範囲

本ガイドは組織横断の Next.js プロジェクト全般を対象とする。
複数リポジトリの実態調査に基づき、共通パターンと残課題を整理している。

## 全プロジェクト品質ゲート整備状況

2026-02 時点の実態調査に基づく。

| 品質ゲート             | プロジェクト A | プロジェクト B | プロジェクト C | プロジェクト D | プロジェクト E | プロジェクト F | プロジェクト G |
| ---------------------- | :------------: | :------------: | :------------: | :------------: | :------------: | :------------: | :------------: |
| **テスト (Unit)**      |    o (Jest)    |   o (Vitest)   |    o (Jest)    |    o (Jest)    |    o (Jest)    |   o (Vitest)   |       x        |
| **カバレッジ 70%**     |   △ (8-60%)    |  **o (70%)**   |  **o (70%)**   |  **o (70%)**   |  △ (閾値なし)  |  △ (閾値なし)  |       x        |
| **E2E テスト**         | o (Playwright) |       x        |       x        | o (Playwright) |       x        |       x        |       x        |
| **ESLint**             |    o (Flat)    |    o (Flat)    |    o (Flat)    |    o (Flat)    |    o (Flat)    |    o (Flat)    |   △ (Biome)    |
| **Prettier / fmt**     |       o        |       o        |       o        |       o        |       o        |       x        |   △ (Biome)    |
| **CI/CD**              |       o        |       o        |       o        |       o        |       o        |       o        |       o        |
| **husky + commitlint** |       o        |       o        |       o        | △ (husky のみ) |       o        |       x        |       x        |
| **lint-staged**        |       o        |       o        |       x        |       x        |       o        |       x        |       x        |
| **CLAUDE.md**          |       x        |     **o**      |       x        |       x        |       x        |       x        |       x        |
| **DevContainer**       |   o (1.54.0)   |   o (latest)   |       x        |       x        |   o (latest)   |   o (1.48.0)   |       x        |

**模範プロジェクト**: プロジェクト B — 70% カバレッジ、CLAUDE.md、DevContainer latest、全品質ゲート達成

## 共通セットアップ項目

以下はすべての Next.js プロジェクトに適用すべき項目。

### 優先度: 高

#### 1. テスト環境構築とカバレッジ 70% 達成

テストフレームワークの選択は 2 パターンが確立されている。

**パターン A: Jest + Testing Library**（4 プロジェクトで採用）

```bash
npm install -D jest @jest/globals jest-environment-jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event @types/jest
```

`jest.config.js`（`next/jest` を利用）:

```js
const nextJest = require('next/jest');
const createJestConfig = nextJest({ dir: './' });

module.exports = createJestConfig({
  coverageProvider: 'v8',
  testEnvironment: 'jsdom',
  setupFilesAfterSetup: ['<rootDir>/jest.setup.js'],
  moduleNameMapper: { '^@/(.*)$': '<rootDir>/$1' },
  coverageThreshold: {
    global: { branches: 70, functions: 70, lines: 70, statements: 70 },
  },
});
```

**パターン B: Vitest**（2 プロジェクトで採用）

```bash
npm install -D vitest @vitest/coverage-v8 @testing-library/react @testing-library/jest-dom jsdom
```

`vitest.config.ts`:

```ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    coverage: {
      provider: 'v8',
      thresholds: { lines: 70, branches: 70, functions: 70, statements: 70 },
    },
  },
});
```

**既存プロジェクトのカバレッジ引き上げ**（閾値が低いプロジェクト向け）:

1. `npm run test:coverage` で現在の実カバレッジを計測
2. 各指標を +10% ずつ段階的に引き上げ
3. 最終目標: 全指標 70%（模範プロジェクトと同水準）

#### 2. ESLint Flat Config + Prettier 統一

全プロジェクトで ESLint Flat Config (`eslint.config.mjs`) への統一が進んでいる。

```bash
npm install -D eslint @eslint/js typescript-eslint eslint-config-prettier prettier
```

**推奨スクリプト**:

```json
{
  "lint": "next lint --max-warnings 0",
  "lint:fix": "next lint --fix",
  "format": "prettier --write .",
  "format:check": "prettier --check ."
}
```

> `--max-warnings 999` や `continue-on-error: true` は使わない。明示的に `--max-warnings 0` を設定する。

#### 3. CI/CD パイプライン構築

確立されたパイプラインパターン:

```
typecheck → lint → format:check → test (coverage) → build → e2e → security
```

**最小構成** (`ci.yml`):

```yaml
jobs:
  typecheck:
    steps:
      - run: npm run typecheck
  lint:
    steps:
      - run: npm run lint
      - run: npm run format:check
  test:
    steps:
      - run: npm run test:ci
  build:
    needs: [typecheck, lint, test]
    steps:
      - run: npm run build
```

**発展構成**:

- `code-quality.yml`: lint + format + typecheck
- `security.yml`: npm audit + CodeQL
- `deploy.yml`: Vercel / その他プラットフォーム

#### 4. husky + commitlint + lint-staged 導入

**参考**: `/setup-husky` コマンドで最小構成を導入可能。

```bash
npm install -D husky @commitlint/cli @commitlint/config-conventional lint-staged
```

**commitlint.config.js**:

```js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'body-max-line-length': [2, 'always', 120],
  },
};
```

**lint-staged.config.js**:

```js
module.exports = {
  '*.{ts,tsx,js,jsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
  '*.{css,scss}': ['prettier --write'],
};
```

**pre-push hook**（typecheck + lint + format + test を実行）:

```bash
npm run typecheck && npm run lint && npm run format:check && npm run test
```

### 優先度: 中

#### 5. CLAUDE.md 作成

7 プロジェクト中 1 プロジェクトのみ作成済み。他の全プロジェクトで未作成。

**含めるべき内容**:

- **技術スタック**: Next.js バージョン、React バージョン、CSS フレームワーク（Tailwind CSS 3/4）
- **バックエンド連携**: Supabase / Firebase / 外部 API の構成
- **テスト戦略**: Jest or Vitest の選択理由、E2E の有無
- **デプロイ先**: Vercel / その他
- **品質ゲート**: pre-commit / pre-push の実行内容

#### 6. E2E テスト導入（Playwright）

2 プロジェクトで導入済み。他プロジェクトへの展開を推奨。

```bash
npm install -D @playwright/test
npx playwright install
```

**playwright.config.ts**:

```ts
export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  projects: process.env.CI
    ? [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }]
    : [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
        { name: 'webkit', use: { ...devices['Desktop Safari'] } },
      ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: true,
  },
});
```

> CI では Chromium のみに限定しフィードバックを高速化するパターンが実績あり。

#### 7. Claude Code ワークフロー導入

4 プロジェクトで導入済み。

- `claude.yml`: `@claude` メンション対応
- `claude-code-review.yml`: PR 自動レビュー

**参考**: config リポジトリの `.github/workflows/claude.yml` をテンプレートとして使用。

### 優先度: 低

#### 8. DevContainer 整備

| 状態                       | ベースイメージ | プロジェクト数 |
| -------------------------- | -------------- | :------------: |
| **模範**（latest）         | latest         |       2        |
| 整備済み（旧バージョン）   | 1.48.0〜1.64.0 |       2        |
| 更新 + Features 整理が必要 | 1.54.0         |       1        |
| 未作成                     | なし           |       2        |

**冗長 Features の削除**（一部プロジェクト向け）:

- 削除候補: git, pnpm, github-cli, jq-likes, supabase-cli（ベースイメージに含まれるもの）
- 残すべき Features: docker-in-docker, playwright（プロジェクト固有）

#### 9. Biome 採用プロジェクトの対応

一部プロジェクトでは ESLint + Prettier の代わりに Biome を採用している。Biome は lint + format を 1 ツールで提供するが、テスト環境が未整備。

**優先対応**: テスト環境の構築（Vitest 推奨）とカバレッジ閾値の設定。

## プロジェクト別の残課題サマリー

| プロジェクト | 主な残課題                                                 |
| ------------ | ---------------------------------------------------------- |
| **A**        | カバレッジ閾値引き上げ（8→70%）、lint 厳格化、CLAUDE.md    |
| **B**        | （模範 — 残課題なし）                                      |
| **C**        | lint-staged 導入、CLAUDE.md、DevContainer 新規作成         |
| **D**        | commitlint 追加、lint-staged 導入、CLAUDE.md、DevContainer |
| **E**        | カバレッジ閾値設定（70%）、CLAUDE.md                       |
| **F**        | Prettier・husky・commitlint 導入、CLAUDE.md                |
| **G**        | テスト環境構築、husky・commitlint 導入、CLAUDE.md          |
