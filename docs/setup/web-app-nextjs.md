# Web アプリ (Next.js) セットアップガイド

## テスト環境構築とカバレッジ 70% 達成

テストフレームワークの選択は 2 パターンが確立されている。

**パターン A: Jest + Testing Library**

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

**パターン B: Vitest**

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

**既存プロジェクトのカバレッジ引き上げ**:

1. `npm run test:coverage` で現在の実カバレッジを計測
2. 各指標を +10% ずつ段階的に引き上げ
3. 最終目標: 全指標 70%

## Biome（Lint + Format）

ESLint + Prettier の代わりに **Biome を推奨**する。1 ツールで lint + format を高速に実行できる。

```bash
npm install -D --save-exact @biomejs/biome
npx @biomejs/biome init
```

`biome.json`:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "rules": {
      "recommended": true,
      "suspicious": {
        "noConsole": {
          "level": "error",
          "options": {
            "allow": ["error", "warn"]
          }
        }
      }
    }
  },
  "files": {
    "ignore": [".next", "node_modules", "coverage"]
  }
}
```

> `noConsole` は `console.log` / `console.debug` をエラーにし、`console.error` / `console.warn` は許可する。
> ログ出力は `@vercel/logger`、エラー通知は Sentry に統一する。

**推奨スクリプト**:

```json
{
  "check": "biome check .",
  "check:fix": "biome check --write .",
  "lint": "biome lint .",
  "format": "biome format .",
  "format:check": "biome format ."
}
```

> `biome check` は lint + format + import 整理を一括実行する。CI では `biome check .` を使う。

### 既存の ESLint + Prettier からの移行

```bash
npx @biomejs/biome migrate eslint
npx @biomejs/biome migrate prettier
```

移行後、不要になったパッケージと設定ファイルを削除する:

- `eslint`, `eslint-config-*`, `eslint-plugin-*`, `@eslint/*`, `typescript-eslint`
- `prettier`, `eslint-config-prettier`
- `eslint.config.mjs` / `.eslintrc.*` / `.prettierrc*`

## Knip（未使用コード検出）

未使用の依存関係・ファイル・export を検出する **Knip を推奨**する。

```bash
npm install -D knip
```

`knip.json`:

```json
{
  "$schema": "https://unpkg.com/knip@5/schema.json",
  "ignore": ["!src/generated/**"],
  "ignoreDependencies": [],
  "next": {
    "entry": ["next.config.{js,ts,mjs}", "src/app/**/*.{ts,tsx}", "src/middleware.ts"]
  }
}
```

> Knip は Next.js プラグインを内蔵しており、`next.config.*` や App Router のエントリを自動検出する。

**推奨スクリプト**:

```json
{
  "knip": "knip"
}
```

CI にも追加:

```yaml
- name: Check unused code
  run: npm run knip
```

## CI/CD パイプライン

```
typecheck → biome check → knip → test (coverage) → build → e2e → security
```

**最小構成** (`ci.yml`):

```yaml
jobs:
  typecheck:
    steps:
      - run: npm run typecheck
  quality:
    steps:
      - run: npx biome check .
      - run: npm run knip
  test:
    steps:
      - run: npm run test:ci
  build:
    needs: [typecheck, quality, test]
    steps:
      - run: npm run build
```

**発展構成**（ワークフロー分割）:

- `code-quality.yml`: typecheck + biome check + knip
- `security.yml`: npm audit + CodeQL
- `deploy.yml`: Vercel / その他プラットフォーム

## husky + commitlint + lint-staged

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
  '*.{ts,tsx,js,jsx,json,css}': ['biome check --write --no-errors-on-unmatched'],
  '*.{md,yml,yaml}': ['biome format --write --no-errors-on-unmatched'],
};
```

**pre-push hook**:

```bash
npm run typecheck && npx biome check . && npm run test
```

## CLAUDE.md

**含めるべき内容**:

- **技術スタック**: Next.js バージョン、React バージョン、CSS フレームワーク（Tailwind CSS 3/4）
- **バックエンド連携**: Supabase / Firebase / 外部 API の構成
- **テスト戦略**: Jest or Vitest の選択理由、E2E の有無
- **デプロイ先**: Vercel / その他
- **品質ゲート**: pre-commit / pre-push の実行内容

## E2E テスト（Playwright）

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

> CI では Chromium のみに限定しフィードバックを高速化する。

## Claude Code ワークフロー

- `claude.yml`: `@claude` メンション対応
- `claude-code-review.yml`: PR 自動レビュー

**参考**: config リポジトリの `.github/workflows/claude.yml` をテンプレートとして使用。

## DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **冗長 Features の削除**: ベースイメージに含まれるもの（git, pnpm, github-cli, jq-likes, supabase-cli）は削除
- **残すべき Features**: docker-in-docker, playwright（プロジェクト固有）

## ロギング & モニタリング

Next.js + Vercel 構成では以下の2ツールを**必ず導入**する。

### @vercel/logger（構造化ロギング）

```bash
npm install @vercel/logger
```

Vercel のログインフラと連携した構造化ロギングライブラリ。JSON 形式で出力し、Vercel Dashboard / Log Drains で検索・集計しやすい形式になる。

**基本的な使い方**:

```typescript
import { logger } from '@vercel/logger';

// Server Components / API Routes での使用例
logger.info('User authenticated', { userId: user.id });
logger.warn('Rate limit approaching', { remaining: 5 });
logger.error('Supabase query failed', { error: err.message, table: 'users' });
```

**推奨パターン**（モジュール単位でラップ）:

```typescript
// lib/logger.ts
import { logger } from '@vercel/logger';

export const appLogger = logger.child({ service: 'my-app' });
export const dbLogger = logger.child({ service: 'supabase' });
```

**注意事項**:

- クライアントコンポーネント（`'use client'`）では使用不可（サーバーサイド専用）
- `console.log` の代替として Server Components / Route Handlers / Middleware で使用

### Sentry（エラー監視 & パフォーマンス）

```bash
npx @sentry/wizard@latest -i nextjs
```

エラートラッキング、パフォーマンスモニタリング、Session Replay を提供する。Supabase のエラーも Sentry に集約することで、障害の根本原因追跡が容易になる。

**Supabase との連携**:

```typescript
// app/api/users/route.ts
import * as Sentry from '@sentry/nextjs';
import { createClient } from '@/lib/supabase/server';

export async function GET() {
  const supabase = createClient();
  const { data, error } = await supabase.from('users').select('*');

  if (error) {
    Sentry.captureException(error, {
      tags: { supabase_table: 'users', operation: 'select' },
    });
    return Response.json({ error: 'DB error' }, { status: 500 });
  }

  return Response.json(data);
}
```

詳細な設定は [Sentry セットアップガイド](../sentry-setup-guide.md) を参照。

### ロギング設計指針

| ツール                    | 用途                                 | 環境           |
| ------------------------- | ------------------------------------ | -------------- |
| `@vercel/logger`          | 構造化ログ（操作ログ、デバッグ）     | サーバーサイド |
| Sentry (`@sentry/nextjs`) | エラー監視・アラート・パフォーマンス | 全環境         |

**原則**:

- `@vercel/logger` で操作ログを記録し、Vercel Dashboard で確認
- 例外・エラーは Sentry に `captureException` してアラートを受け取る
- `console.log` の本番利用は禁止 → Biome の `noConsole` ルールで CI がブロック

## 関連ドキュメント

| ドキュメント                                          | 説明                                  |
| ----------------------------------------------------- | ------------------------------------- |
| [Sentry セットアップガイド](../sentry-setup-guide.md) | Next.js 14+ 向けの Sentry 設定        |
| [MCP サーバーガイド](../mcp-servers-guide.md)         | Linear, Playwright, Supabase 等の連携 |
| [ツールカタログ](../tool-catalog.md)                  | 環境×ツールのマトリクス               |
| [config-base イメージ](../using-config-base-image.md) | DevContainer ベースイメージの詳細     |
