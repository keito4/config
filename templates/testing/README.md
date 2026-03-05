# Testing Templates

Next.js プロジェクト向けの包括的なテスト設定テンプレート集です。
cyber_ace_1on1 で実績のある設定を他のリポジトリに適用できます。

## テストピラミッド

```
           /\
          /  \  E2E Tests (少数、遅い、高コスト)
         /----\
        /      \  Regression Tests
       /--------\
      /          \  Integration Tests
     /------------\
    /              \  Component Tests
   /----------------\
  /                  \  Unit Tests (多数、速い、低コスト)
 /____________________\
```

## テスト種別（21種類）

### 基本テスト

| 種別            | ツール                 | 目的                       | 実行頻度   |
| --------------- | ---------------------- | -------------------------- | ---------- |
| **Unit**        | Jest                   | 個別関数・モジュールの検証 | 毎コミット |
| **Component**   | Jest + Testing Library | UIコンポーネントの検証     | 毎コミット |
| **Snapshot**    | Jest                   | UIスナップショットの検証   | 毎コミット |
| **Integration** | Jest                   | 複数サービスの連携検証     | 毎PR       |
| **E2E**         | Playwright             | ユーザーフロー全体の検証   | 毎PR       |

### 品質保証テスト

| 種別           | ツール                 | 目的                       | 実行頻度           |
| -------------- | ---------------------- | -------------------------- | ------------------ |
| **API**        | Jest + node-mocks-http | REST APIエンドポイント検証 | 毎PR               |
| **Regression** | Jest + Playwright      | 既知バグの再発防止         | main/production PR |
| **Smoke**      | Jest                   | 基本動作確認（デプロイ後） | デプロイ後         |
| **Contract**   | Jest                   | API契約の検証              | main/production PR |
| **Scenario**   | Jest                   | ビジネスシナリオの検証     | 主要機能変更時     |
| **Visual**     | Playwright             | UI見た目の変更検出         | UI変更時           |
| **A11y**       | Playwright + axe-core  | アクセシビリティ準拠       | UI変更時           |

### 高度なテスト

| 種別               | ツール     | 目的                   | 実行頻度       |
| ------------------ | ---------- | ---------------------- | -------------- |
| **Property-based** | fast-check | ランダム入力による検証 | 主要機能変更時 |
| **Mutation**       | Stryker    | テスト品質の検証       | 週次/手動      |

### パフォーマンス・負荷テスト

| 種別            | ツール                  | 目的                | 実行頻度        |
| --------------- | ----------------------- | ------------------- | --------------- |
| **Performance** | Playwright + Lighthouse | Core Web Vitals測定 | リリース前      |
| **Load**        | k6 / Artillery          | 負荷耐性検証        | リリース前/手動 |

### セキュリティ・インフラテスト

| 種別               | ツール          | 目的                          | 実行頻度 |
| ------------------ | --------------- | ----------------------------- | -------- |
| **Security**       | Jest            | セキュリティヘッダー・XSS対策 | 毎PR     |
| **Database**       | Jest + Supabase | マイグレーション・RLS検証     | 毎PR     |
| **Edge Functions** | Deno / Jest     | Supabase Edge Functions検証   | 毎PR     |

### 国際化・SSRテスト

| 種別              | ツール                 | 目的                      | 実行頻度   |
| ----------------- | ---------------------- | ------------------------- | ---------- |
| **i18n**          | Jest + Testing Library | 多言語対応の検証          | 翻訳変更時 |
| **SSR/Hydration** | Playwright             | SSR・ハイドレーション検証 | UI変更時   |

## 含まれるファイル

### 設定ファイル

| ファイル                          | レベル        | 説明                             |
| --------------------------------- | ------------- | -------------------------------- |
| `jest.config.js`                  | Minimal       | Jest 基本設定（Next.js 対応）    |
| `jest.setup.js`                   | Minimal       | テスト前セットアップ             |
| `jest.polyfills.js`               | Minimal       | Web API ポリフィル               |
| `playwright.config.ts`            | Standard      | Playwright E2E 設定              |
| `jest.regression.config.js`       | Comprehensive | リグレッション用 Jest 設定       |
| `playwright.regression.config.ts` | Comprehensive | リグレッション用 Playwright 設定 |
| `jest.scenario.config.js`         | Full          | シナリオテスト用 Jest 設定       |
| `ci-test-jobs.yml`                | Standard      | GitHub Actions テストジョブ      |

### サンプルテスト（21種類）

#### 基本テスト

| ファイル                       | レベル   | 説明                     |
| ------------------------------ | -------- | ------------------------ |
| `examples/api-route.test.ts`   | Minimal  | API ルートテスト例       |
| `examples/component.test.tsx`  | Minimal  | コンポーネントテスト例   |
| `examples/hook.test.ts`        | Minimal  | カスタムフックテスト例   |
| `examples/snapshot.test.tsx`   | Minimal  | スナップショットテスト例 |
| `examples/e2e-auth.spec.ts`    | Standard | E2E 認証フローテスト例   |
| `examples/integration.test.ts` | Standard | 統合テスト例             |

#### 品質保証テスト

| ファイル                           | レベル        | 説明                       |
| ---------------------------------- | ------------- | -------------------------- |
| `examples/api.test.ts`             | Standard      | REST APIテスト例           |
| `examples/smoke.test.ts`           | Comprehensive | スモークテスト例           |
| `examples/regression-auth.spec.ts` | Comprehensive | リグレッションテスト例     |
| `examples/contract.test.ts`        | Comprehensive | API契約テスト例            |
| `examples/visual.spec.ts`          | Full          | ビジュアルリグレッション例 |
| `examples/a11y.spec.ts`            | Full          | アクセシビリティテスト例   |

#### 高度なテスト

| ファイル                          | レベル     | 説明                       |
| --------------------------------- | ---------- | -------------------------- |
| `examples/property-based.test.ts` | Full       | Property-basedテスト例     |
| `examples/mutation.config.js`     | Enterprise | ミューテーションテスト設定 |

#### パフォーマンス・負荷テスト

| ファイル                       | レベル     | 説明                         |
| ------------------------------ | ---------- | ---------------------------- |
| `examples/performance.spec.ts` | Enterprise | Core Web Vitalsテスト例      |
| `examples/load.test.ts`        | Enterprise | 負荷テスト例（k6/Artillery） |

#### セキュリティ・インフラテスト

| ファイル                          | レベル     | 説明                   |
| --------------------------------- | ---------- | ---------------------- |
| `examples/security.test.ts`       | Enterprise | セキュリティテスト例   |
| `examples/database.test.ts`       | Enterprise | データベーステスト例   |
| `examples/edge-functions.test.ts` | Enterprise | Edge Functionsテスト例 |

#### 国際化・SSRテスト

| ファイル                         | レベル     | 説明                         |
| -------------------------------- | ---------- | ---------------------------- |
| `examples/i18n.test.tsx`         | Enterprise | 国際化テスト例               |
| `examples/ssr-hydration.spec.ts` | Enterprise | SSR/ハイドレーションテスト例 |

## 使い方

### 方法1: Claude コマンド（推奨）

```bash
# デフォルト（Standard レベル）
/setup-tests

# レベル指定
/setup-tests --level minimal       # Unit + Component + Snapshot
/setup-tests --level standard      # + Integration + E2E + API
/setup-tests --level comprehensive # + Regression + Smoke + Contract
/setup-tests --level full          # + Visual + A11y + Scenario + Property-based
/setup-tests --level enterprise    # + Performance + Load + Security + DB + Edge + i18n + SSR + Mutation

# カバレッジ閾値指定
/setup-tests --coverage-threshold 80
```

### 方法2: 手動コピー

```bash
# 基本設定
cp templates/testing/jest.config.js ./
cp templates/testing/jest.setup.js ./
cp templates/testing/jest.polyfills.js ./
cp templates/testing/playwright.config.ts ./

# Comprehensive レベル追加
cp templates/testing/jest.regression.config.js ./
cp templates/testing/playwright.regression.config.ts ./

# Full レベル追加
cp templates/testing/jest.scenario.config.js ./
```

## レベル比較表

| テスト種別     | Minimal | Standard | Comprehensive | Full | Enterprise |
| -------------- | :-----: | :------: | :-----------: | :--: | :--------: |
| Unit           |   ✅    |    ✅    |      ✅       |  ✅  |     ✅     |
| Component      |   ✅    |    ✅    |      ✅       |  ✅  |     ✅     |
| Snapshot       |   ✅    |    ✅    |      ✅       |  ✅  |     ✅     |
| Integration    |   ❌    |    ✅    |      ✅       |  ✅  |     ✅     |
| E2E            |   ❌    |    ✅    |      ✅       |  ✅  |     ✅     |
| API            |   ❌    |    ✅    |      ✅       |  ✅  |     ✅     |
| Regression     |   ❌    |    ❌    |      ✅       |  ✅  |     ✅     |
| Smoke          |   ❌    |    ❌    |      ✅       |  ✅  |     ✅     |
| Contract       |   ❌    |    ❌    |      ✅       |  ✅  |     ✅     |
| Scenario       |   ❌    |    ❌    |      ❌       |  ✅  |     ✅     |
| Visual         |   ❌    |    ❌    |      ❌       |  ✅  |     ✅     |
| A11y           |   ❌    |    ❌    |      ❌       |  ✅  |     ✅     |
| Property-based |   ❌    |    ❌    |      ❌       |  ✅  |     ✅     |
| Performance    |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |
| Load           |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |
| Security       |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |
| Database       |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |
| Edge Functions |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |
| i18n           |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |
| SSR/Hydration  |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |
| Mutation       |   ❌    |    ❌    |      ❌       |  ❌  |     ✅     |

## 依存パッケージ

### Minimal Level

```bash
npm install -D \
  jest @jest/types jest-environment-jsdom \
  @testing-library/react @testing-library/jest-dom @testing-library/user-event \
  @types/jest ts-jest \
  @faker-js/faker
```

### Standard Level (+)

```bash
npm install -D @playwright/test node-mocks-http @types/node-mocks-http
npx playwright install --with-deps chromium
```

### Full Level (+)

```bash
npm install -D @axe-core/playwright fast-check
```

### Enterprise Level (+)

```bash
# パフォーマンス・負荷テスト
npm install -D lighthouse
# k6 は別途インストール: https://k6.io/docs/getting-started/installation/

# ミューテーションテスト
npm install -D @stryker-mutator/core @stryker-mutator/jest-runner @stryker-mutator/typescript-checker
```

## package.json スクリプト

### 全スクリプト一覧

```json
{
  "scripts": {
    // Minimal
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --coverage --watchAll=false",

    // Standard
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed",
    "test:api": "jest tests/api/",
    "test:all": "npm run test && npm run test:e2e",

    // Comprehensive
    "test:regression": "npm run test:regression:api && npm run test:regression:e2e",
    "test:regression:api": "jest --config jest.regression.config.js",
    "test:regression:e2e": "playwright test --config playwright.regression.config.ts",
    "test:smoke": "jest --config jest.regression.config.js tests/regression/api-smoke.test.ts",
    "test:contract": "jest tests/contract/",

    // Full
    "test:scenario": "jest --config jest.scenario.config.js --runInBand",
    "test:visual": "playwright test tests/visual/",
    "test:visual:update": "playwright test tests/visual/ --update-snapshots",
    "test:a11y": "playwright test tests/a11y/",
    "test:property": "jest tests/property/",

    // Enterprise
    "test:performance": "playwright test tests/performance/",
    "test:load": "k6 run tests/load/api-load.js",
    "test:security": "jest tests/security/",
    "test:database": "jest tests/database/",
    "test:edge": "cd supabase/functions && deno test --allow-all",
    "test:i18n": "jest tests/i18n/",
    "test:ssr": "playwright test tests/ssr/",
    "test:mutation": "stryker run"
  }
}
```

## ディレクトリ構造

```
project/
├── __tests__/                    # ルートレベルの単体テスト
├── app/
│   └── api/
│       └── example/
│           └── __tests__/        # API ルートテスト
│               └── route.test.ts
├── components/
│   └── __tests__/                # コンポーネントテスト
│       └── Button.test.tsx
├── hooks/
│   └── __tests__/                # フックテスト
│       └── useCounter.test.ts
├── lib/
│   └── __tests__/                # ユーティリティテスト
│       └── utils.test.ts
├── supabase/
│   └── functions/
│       └── hello-world/
│           └── index.test.ts     # Edge Functions テスト
└── tests/
    ├── e2e/                      # E2E テスト
    │   └── auth.spec.ts
    ├── integration/              # 統合テスト
    │   └── user-flow.test.ts
    ├── api/                      # API テスト
    │   └── endpoints.test.ts
    ├── regression/               # リグレッションテスト
    │   ├── api-smoke.test.ts     # スモークテスト
    │   ├── auth-regression.spec.ts
    │   └── helpers/
    │       └── auth.ts
    ├── contract/                 # 契約テスト
    │   └── api-contract.test.ts
    ├── scenario/                 # シナリオテスト
    │   └── business-flow.test.ts
    ├── visual/                   # ビジュアルテスト
    │   └── pages.spec.ts
    ├── a11y/                     # アクセシビリティテスト
    │   └── pages.spec.ts
    ├── property/                 # Property-based テスト
    │   └── validators.test.ts
    ├── performance/              # パフォーマンステスト
    │   └── lighthouse.spec.ts
    ├── load/                     # 負荷テスト
    │   ├── api-load.js           # k6 スクリプト
    │   └── artillery.yml         # Artillery 設定
    ├── security/                 # セキュリティテスト
    │   └── headers.test.ts
    ├── database/                 # データベーステスト
    │   └── migrations.test.ts
    ├── i18n/                     # 国際化テスト
    │   └── translations.test.tsx
    └── ssr/                      # SSR テスト
        └── hydration.spec.ts
```

## カスタマイズ

### カバレッジ閾値の変更

`jest.config.js`:

```javascript
coverageThreshold: {
  global: {
    branches: 80,
    functions: 80,
    lines: 80,
    statements: 80,
  },
},
```

### モックの追加

`jest.setup.js`:

```javascript
// Supabase クライアントのモック
jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => ({
    from: jest.fn(() => ({
      select: jest.fn().mockResolvedValue({ data: [], error: null }),
    })),
  })),
}));
```

### Playwright ブラウザの追加

`playwright.config.ts`:

```typescript
projects: [
  { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  { name: 'Mobile Safari', use: { ...devices['iPhone 12'] } },
],
```

### A11y テストのルール調整

```typescript
const results = await new AxeBuilder({ page })
  .exclude('#dynamic-content') // 動的コンテンツを除外
  .disableRules(['color-contrast']) // 特定ルールを無効化
  .analyze();
```

## CI 統合

### GitHub Actions

`ci-test-jobs.yml` の内容を `.github/workflows/ci.yml` に組み込みます。

```yaml
jobs:
  unit-tests:
    # Unit + Component tests
  e2e-tests:
    # E2E tests (PR時)
  regression-tests:
    # Regression tests (main/production PR時)
  visual-tests:
    # Visual tests (UI変更時)
  a11y-tests:
    # Accessibility tests
  security-tests:
    # Security tests (Enterprise)
  performance-tests:
    # Performance tests (Enterprise)
```

### 実行タイミング

| テスト                  | トリガー                |
| ----------------------- | ----------------------- |
| Unit/Component/Snapshot | すべての push/PR        |
| E2E/API                 | PR 時                   |
| Regression/Contract     | main/production への PR |
| Visual/A11y             | UI ファイル変更時       |
| Security/Database       | セキュリティ関連変更時  |
| Performance/Load        | リリース前/手動         |
| Mutation                | 週次/手動               |

## トラブルシューティング

### Jest が動かない

```bash
npx jest --clearCache
npx jest --showConfig
```

### Playwright ブラウザエラー

```bash
npx playwright install --with-deps
```

### ビジュアルテストのスナップショット更新

```bash
npx playwright test tests/visual/ --update-snapshots
```

### CI でのみテストが失敗する

```bash
# ローカルで CI 環境をシミュレート
CI=true npm test
```

### k6 のインストール

```bash
# macOS
brew install k6

# Docker
docker run -i grafana/k6 run - <script.js
```

### Stryker ミューテーションテスト

```bash
npx stryker run
```

## 参照

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Testing Library](https://testing-library.com/docs/)
- [Playwright Documentation](https://playwright.dev/docs/intro)
- [axe-core](https://www.deque.com/axe/)
- [fast-check](https://fast-check.dev/)
- [Stryker Mutator](https://stryker-mutator.io/)
- [k6 Load Testing](https://k6.io/docs/)
- [Artillery](https://www.artillery.io/docs)
- [Lighthouse](https://developer.chrome.com/docs/lighthouse)
- [Codecov](https://docs.codecov.com/)
