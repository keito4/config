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

## バリデーション & 型安全

### Zod（スキーマバリデーション）

```bash
npm install zod
```

API レスポンス・フォーム入力・環境変数の検証を一元化する。Supabase の型と組み合わせて使う。

**基本的な使い方**:

```typescript
import { z } from 'zod';

// スキーマ定義
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

type User = z.infer<typeof UserSchema>;

// API Route でのバリデーション
export async function POST(req: Request) {
  const body = await req.json();
  const result = UserSchema.safeParse(body);

  if (!result.success) {
    return Response.json({ errors: result.error.flatten() }, { status: 400 });
  }

  // result.data は型安全
  const user = result.data;
}
```

**Supabase の型と組み合わせる**:

```typescript
import { z } from 'zod';
import type { Database } from '@/lib/supabase/types';

type Row = Database['public']['Tables']['users']['Row'];

// DB の型から Zod スキーマを構築
const UserInsertSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
}) satisfies z.ZodType<Partial<Row>>;
```

### @t3-oss/env-nextjs（環境変数の型安全化）

```bash
npm install @t3-oss/env-nextjs zod
```

`.env` の未設定・型ミスをビルド時に検知する。`process.env.XXX` の生アクセスを禁止し、型付き `env` オブジェクト経由に統一する。

**`src/env.ts`**:

```typescript
import { createEnv } from '@t3-oss/env-nextjs';
import { z } from 'zod';

export const env = createEnv({
  server: {
    SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
    SENTRY_AUTH_TOKEN: z.string().optional(),
  },
  client: {
    NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
    NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
    NEXT_PUBLIC_SENTRY_DSN: z.string().url().optional(),
  },
  runtimeEnv: {
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
    SENTRY_AUTH_TOKEN: process.env.SENTRY_AUTH_TOKEN,
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    NEXT_PUBLIC_SENTRY_DSN: process.env.NEXT_PUBLIC_SENTRY_DSN,
  },
});
```

> `next.config.ts` で `import './src/env'` を追加するとビルド時に検証が走る。

## フォーム管理（react-hook-form + Zod）

```bash
npm install react-hook-form @hookform/resolvers zod
```

フォームバリデーションを Zod スキーマで統一し、型安全なフォームを実装する。

**基本的な使い方**:

```typescript
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email('有効なメールアドレスを入力してください'),
  password: z.string().min(8, '8文字以上で入力してください'),
});

type FormValues = z.infer<typeof schema>;

export function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: FormValues) => {
    // data は型安全
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <p>{errors.email.message}</p>}
      <input type="password" {...register('password')} />
      {errors.password && <p>{errors.password.message}</p>}
      <button type="submit" disabled={isSubmitting}>
        ログイン
      </button>
    </form>
  );
}
```

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
typecheck → biome check → knip → test (coverage + a11y) → build (bundle check) → e2e (+ a11y) → security
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

## アクセシビリティテスト（axe）

WCAG 違反を自動検出する。E2E とユニットテストの両レイヤーでカバーする。

### @axe-core/playwright（E2E での a11y チェック）

```bash
npm install -D @axe-core/playwright
```

既存の Playwright テストに数行追加するだけで、ページ全体のアクセシビリティ違反を検出できる。

**`tests/e2e/accessibility.spec.ts`**:

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('アクセシビリティ', () => {
  test('トップページに WCAG 違反がないこと', async ({ page }) => {
    await page.goto('/');
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });

  test('ログインページに WCAG 違反がないこと', async ({ page }) => {
    await page.goto('/login');
    const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa']).analyze();
    expect(results.violations).toEqual([]);
  });
});
```

### jest-axe（ユニットテストでの a11y チェック）

```bash
npm install -D jest-axe
```

Testing Library と組み合わせてコンポーネント単位でチェックする。

**使い方**:

```typescript
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { LoginForm } from '@/components/LoginForm';

expect.extend(toHaveNoViolations);

test('LoginForm にアクセシビリティ違反がないこと', async () => {
  const { container } = render(<LoginForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

> E2E はページ全体、ユニットは個別コンポーネントの責務として使い分ける。

## バンドルサイズ監視（@next/bundle-analyzer）

```bash
npm install -D @next/bundle-analyzer
```

バンドルサイズの肥大化を可視化し、依存追加時の意図しないサイズ増加を防ぐ。

**`next.config.ts`**:

```typescript
import bundleAnalyzer from '@next/bundle-analyzer';

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
});

export default withBundleAnalyzer({
  // 既存の next config
});
```

**`package.json` スクリプト**:

```json
{
  "analyze": "ANALYZE=true npm run build"
}
```

**CI でのサイズ閾値チェック**（オプション）:

```yaml
- name: Build and check bundle size
  run: npm run build
  env:
    NEXT_TELEMETRY_DISABLED: 1
# .next/analyze/ に生成されたレポートをアーティファクトとして保存
- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: bundle-report
    path: .next/analyze/
```

> `npm run analyze` でブラウザにバンドルツリーが表示される。依存追加 PR 時に手動実行して確認する運用を推奨。

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

### @vercel/analytics + @vercel/speed-insights（アナリティクス）

```bash
npm install @vercel/analytics @vercel/speed-insights
```

Vercel デプロイなら追加コスト・設定なしで Core Web Vitals とページビューを収集できる。

**`app/layout.tsx` に2行追加するだけ**:

```typescript
import { Analytics } from '@vercel/analytics/react';
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja">
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
```

| コンポーネント      | 収集データ                                 |
| ------------------- | ------------------------------------------ |
| `<Analytics />`     | ページビュー・ユニークビジター・リファラー |
| `<SpeedInsights />` | LCP / FID / CLS 等の Core Web Vitals       |

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
