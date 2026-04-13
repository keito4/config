---
description: Setup comprehensive testing infrastructure for Next.js projects
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(npm:*), Bash(pnpm:*), Bash(npx:*), Bash(node:*), Bash(ls:*), Bash(mkdir:*), Bash(cp:*), Task, Glob, Grep
argument-hint: '[--level minimal|standard|comprehensive|full] [--coverage-threshold NUMBER] [--dry-run]'
---

# Setup Tests Command

Next.js プロジェクトに包括的なテスト基盤をセットアップします。
実績のある設定テンプレートとして、他のリポジトリに適用できます。

## テストピラミッド

```
           /\
          /  \  E2E Tests (少数、遅い)
         /----\
        /      \  Regression Tests
       /--------\
      /          \  Integration Tests
     /------------\
    /              \  Component Tests
   /----------------\
  /                  \  Unit Tests (多数、速い)
 /____________________\
```

## テスト種別一覧（21種類）

### 基本テスト

| 種別            | ツール                 | 目的                 | ファイル配置                      |
| --------------- | ---------------------- | -------------------- | --------------------------------- |
| **Unit**        | Jest                   | 個別関数・モジュール | `__tests__/*.test.ts`             |
| **Component**   | Jest + Testing Library | UIコンポーネント     | `components/__tests__/*.test.tsx` |
| **Integration** | Jest                   | 複数サービス連携     | `tests/integration/*.test.ts`     |
| **E2E**         | Playwright             | ユーザーフロー       | `tests/e2e/*.spec.ts`             |

### 品質保証テスト

| 種別           | ツール                | 目的                     | ファイル配置                         |
| -------------- | --------------------- | ------------------------ | ------------------------------------ |
| **Regression** | Jest + Playwright     | リグレッション防止       | `tests/regression/*`                 |
| **Smoke**      | Jest                  | 基本動作確認             | `tests/regression/api-smoke.test.ts` |
| **Scenario**   | Jest                  | ビジネスシナリオ         | `tests/scenario/*.test.ts`           |
| **Visual**     | Playwright            | ビジュアルリグレッション | `tests/visual/*.spec.ts`             |
| **A11y**       | Playwright + axe-core | アクセシビリティ         | `tests/a11y/*.spec.ts`               |

### 高度なテスト

| 種別               | ツール     | 目的               | ファイル配置                               |
| ------------------ | ---------- | ------------------ | ------------------------------------------ |
| **Contract**       | Jest       | API契約検証        | `tests/contract/*.test.ts`                 |
| **Snapshot**       | Jest       | UIスナップショット | `components/__tests__/*.snapshot.test.tsx` |
| **Property-based** | fast-check | ランダム入力検証   | `tests/property/*.test.ts`                 |
| **Mutation**       | Stryker    | テスト品質検証     | `stryker.conf.js`                          |

### パフォーマンス・負荷テスト

| 種別            | ツール                  | 目的            | ファイル配置                  |
| --------------- | ----------------------- | --------------- | ----------------------------- |
| **Performance** | Playwright + Lighthouse | Core Web Vitals | `tests/performance/*.spec.ts` |
| **Load**        | k6 / Artillery          | 負荷耐性        | `tests/load/*.js`             |

### セキュリティ・インフラテスト

| 種別               | ツール                 | 目的                      | ファイル配置                         |
| ------------------ | ---------------------- | ------------------------- | ------------------------------------ |
| **Security**       | Jest                   | セキュリティヘッダー・XSS | `tests/security/*.test.ts`           |
| **Database**       | Jest + Supabase        | マイグレーション・RLS     | `tests/database/*.test.ts`           |
| **Edge Functions** | Deno / Jest            | Edge Functions検証        | `supabase/functions/*/index.test.ts` |
| **API**            | Jest + node-mocks-http | REST API検証              | `tests/api/*.test.ts`                |

### 国際化・SSRテスト

| 種別              | ツール                 | 目的                  | ファイル配置            |
| ----------------- | ---------------------- | --------------------- | ----------------------- |
| **i18n**          | Jest + Testing Library | 多言語対応            | `tests/i18n/*.test.tsx` |
| **SSR/Hydration** | Playwright             | SSR・ハイドレーション | `tests/ssr/*.spec.ts`   |

## Step 1: Parse Arguments

引数から設定を読み取る：

- `--level LEVEL`: テストレベル（デフォルト: `standard`）
  - `minimal`: Unit + Component + Snapshot のみ
  - `standard`: minimal + Integration + E2E + API
  - `comprehensive`: standard + Regression + Smoke + Contract
  - `full`: comprehensive + Visual + A11y + Scenario + Property-based
  - `enterprise`: full + Performance + Load + Security + Database + Edge + i18n + SSR + Mutation
- `--coverage-threshold NUMBER`: カバレッジ閾値（デフォルト: 70）
- `--dry-run`: 変更を適用せず、差分のみ表示

## Step 2: Detect Project Structure

プロジェクト構造を検出：

```bash
# ファイル存在確認
ls -la package.json next.config.* tsconfig.json 2>/dev/null

# 既存のテスト設定確認
ls -la jest.config.* playwright.config.* vitest.config.* 2>/dev/null

# パッケージマネージャー検出
ls -la package-lock.json pnpm-lock.yaml yarn.lock bun.lockb 2>/dev/null
```

### 検出結果を表示：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Project Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework: Next.js
Package Manager: {npm|pnpm|yarn|bun}
TypeScript: {Yes|No}
Existing Tests: {Jest|Playwright|Vitest|None}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 3: Install Dependencies

### レベル別依存パッケージ

#### Minimal Level

```bash
npm install -D \
  jest @jest/types jest-environment-jsdom \
  @testing-library/react @testing-library/jest-dom @testing-library/user-event \
  @types/jest ts-jest \
  @faker-js/faker
```

#### Standard Level (Minimal +)

```bash
npm install -D @playwright/test node-mocks-http @types/node-mocks-http

# ブラウザインストール
npx playwright install --with-deps chromium
```

#### Comprehensive Level (Standard +)

```bash
# 追加の設定ファイルのみ（追加パッケージなし）
```

#### Full Level (Comprehensive +)

```bash
npm install -D @axe-core/playwright fast-check
```

#### Enterprise Level (Full +)

```bash
# パフォーマンス・負荷テスト
npm install -D lighthouse
# k6 は別途インストール: https://k6.io/docs/getting-started/installation/

# ミューテーションテスト
npm install -D @stryker-mutator/core @stryker-mutator/jest-runner @stryker-mutator/typescript-checker

# セキュリティ・i18n（追加設定ファイルのみ）
```

## Step 4: Create Configuration Files

### 4.1 基本設定（全レベル共通）

テンプレートからコピー：

- `jest.config.js` - Jest 基本設定
- `jest.setup.js` - テスト前セットアップ
- `jest.polyfills.js` - Web API ポリフィル

### 4.2 Standard Level 追加

- `playwright.config.ts` - Playwright E2E 設定

### 4.3 Comprehensive Level 追加

- `jest.regression.config.js` - リグレッションテスト用 Jest 設定
- `playwright.regression.config.ts` - リグレッションテスト用 Playwright 設定

### 4.4 Full Level 追加

- `jest.scenario.config.js` - シナリオテスト用 Jest 設定

## Step 5: Update package.json Scripts

### Minimal Level

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --coverage --watchAll=false"
  }
}
```

### Standard Level (+)

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:headed": "playwright test --headed",
    "test:all": "npm run test && npm run test:e2e"
  }
}
```

### Comprehensive Level (+)

```json
{
  "scripts": {
    "test:regression": "npm run test:regression:api && npm run test:regression:e2e",
    "test:regression:api": "jest --config jest.regression.config.js",
    "test:regression:e2e": "playwright test --config playwright.regression.config.ts",
    "test:smoke": "jest --config jest.regression.config.js tests/regression/api-smoke.test.ts"
  }
}
```

### Full Level (+)

```json
{
  "scripts": {
    "test:scenario": "jest --config jest.scenario.config.js --runInBand",
    "test:visual": "playwright test tests/visual/",
    "test:visual:update": "playwright test tests/visual/ --update-snapshots",
    "test:a11y": "playwright test tests/a11y/",
    "test:property": "jest tests/property/"
  }
}
```

### Enterprise Level (+)

```json
{
  "scripts": {
    "test:performance": "playwright test tests/performance/",
    "test:load": "k6 run tests/load/api-load.js",
    "test:security": "jest tests/security/",
    "test:database": "jest tests/database/",
    "test:edge": "cd supabase/functions && deno test --allow-all",
    "test:api": "jest tests/api/",
    "test:i18n": "jest tests/i18n/",
    "test:ssr": "playwright test tests/ssr/",
    "test:mutation": "stryker run",
    "test:contract": "jest tests/contract/"
  }
}
```

## Step 6: Create Directory Structure

### Minimal Level

```bash
mkdir -p __tests__
mkdir -p components/__tests__
mkdir -p hooks/__tests__
mkdir -p lib/__tests__
```

### Standard Level (+)

```bash
mkdir -p tests/e2e
mkdir -p tests/integration
```

### Comprehensive Level (+)

```bash
mkdir -p tests/regression
mkdir -p tests/regression/helpers
```

### Full Level (+)

```bash
mkdir -p tests/scenario
mkdir -p tests/visual
mkdir -p tests/a11y
mkdir -p tests/property
```

### Enterprise Level (+)

```bash
mkdir -p tests/performance
mkdir -p tests/load
mkdir -p tests/security
mkdir -p tests/database
mkdir -p tests/api
mkdir -p tests/i18n
mkdir -p tests/ssr
mkdir -p tests/contract
```

## Step 7: Create Sample Tests

テンプレートから配置（レベルに応じて）：

| レベル        | サンプル                                                                                                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Minimal       | `api-route.test.ts`, `component.test.tsx`, `hook.test.ts`, `snapshot.test.tsx`                                                                                            |
| Standard      | + `e2e-auth.spec.ts`, `api.test.ts`                                                                                                                                       |
| Comprehensive | + `smoke.test.ts`, `regression-auth.spec.ts`, `integration.test.ts`, `contract.test.ts`                                                                                   |
| Full          | + `visual.spec.ts`, `a11y.spec.ts`, `property-based.test.ts`                                                                                                              |
| Enterprise    | + `performance.spec.ts`, `load.test.ts`, `security.test.ts`, `database.test.ts`, `edge-functions.test.ts`, `i18n.test.tsx`, `ssr-hydration.spec.ts`, `mutation.config.js` |

## Step 8: Update CI Workflow

`.github/workflows/ci.yml` に追加：

### Minimal Level

```yaml
unit-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v6
    - uses: actions/setup-node@v6
      with:
        node-version: '22'
        cache: 'npm'
    - run: npm ci
    - run: npm run test:ci
    - uses: codecov/codecov-action@v6
```

### Standard Level (+)

```yaml
e2e-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v6
    - uses: actions/setup-node@v6
    - run: npm ci
    - run: npx playwright install --with-deps chromium
    - run: npm run build
    - run: |
        npm start &
        sleep 10
        npm run test:e2e
```

### Comprehensive Level (+)

```yaml
regression-tests:
  runs-on: ubuntu-latest
  if: github.base_ref == 'main' || github.base_ref == 'production'
  steps:
    - uses: actions/checkout@v6
    - uses: actions/setup-node@v6
    - run: npm ci
    - run: npx playwright install --with-deps chromium
    - run: npm run build
    - run: |
        npm start &
        sleep 10
        npm run test:regression
```

### Full Level (+)

```yaml
visual-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v6
    - uses: actions/setup-node@v6
    - run: npm ci
    - run: npx playwright install --with-deps
    - run: npm run build
    - run: npm run test:visual
    - uses: actions/upload-artifact@v7
      if: failure()
      with:
        name: visual-diff
        path: test-results/

a11y-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v6
    - uses: actions/setup-node@v6
    - run: npm ci
    - run: npx playwright install --with-deps chromium
    - run: npm run build
    - run: npm run test:a11y
```

## Step 9: Update .gitignore

```
# Test coverage
coverage/

# Playwright
playwright-report/
playwright/.cache/
test-results/

# Visual test snapshots (optional - commit these for CI)
# tests/visual/*.spec.ts-snapshots/
```

## Step 10: Generate Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Test Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Level: {level}
Coverage Threshold: {threshold}%

Test Types Configured:
✅ Unit Tests
✅ Component Tests
✅ Snapshot Tests
{conditional} Integration Tests
{conditional} E2E Tests
{conditional} API Tests
{conditional} Regression Tests
{conditional} Smoke Tests
{conditional} Contract Tests
{conditional} Scenario Tests
{conditional} Visual Tests
{conditional} Accessibility Tests
{conditional} Property-based Tests
{conditional} Performance Tests
{conditional} Load Tests
{conditional} Security Tests
{conditional} Database Tests
{conditional} Edge Functions Tests
{conditional} i18n Tests
{conditional} SSR/Hydration Tests
{conditional} Mutation Tests

Commands:
• npm test              - Run unit/component tests
• npm run test:coverage - With coverage
• npm run test:e2e      - Run E2E tests
• npm run test:api      - Run API tests
• npm run test:regression - Run regression tests
• npm run test:visual   - Run visual tests
• npm run test:a11y     - Run accessibility tests
• npm run test:performance - Run performance tests
• npm run test:load     - Run load tests
• npm run test:security - Run security tests
• npm run test:mutation - Run mutation tests
• npm run test:all      - Run all tests

Next Steps:
1. Run `npm test` to verify Jest setup
2. Run `npm run test:e2e` to verify Playwright setup
3. Configure CODECOV_TOKEN secret in GitHub
4. Review and customize test configurations

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

## テンプレート一覧

| ファイル                          | 説明                                   |
| --------------------------------- | -------------------------------------- |
| `jest.config.js`                  | Jest 設定（Next.js 対応）              |
| `jest.setup.js`                   | テスト前セットアップ（モック設定）     |
| `jest.polyfills.js`               | Web API ポリフィル                     |
| `jest.regression.config.js`       | リグレッションテスト用 Jest 設定       |
| `jest.scenario.config.js`         | シナリオテスト用 Jest 設定             |
| `playwright.config.ts`            | Playwright E2E 設定                    |
| `playwright.regression.config.ts` | リグレッションテスト用 Playwright 設定 |
| `ci-test-jobs.yml`                | GitHub Actions テストジョブ            |

### サンプルテスト（21種類）

#### 基本テスト

| ファイル                      | 説明                   |
| ----------------------------- | ---------------------- |
| `examples/api-route.test.ts`  | API ルートテスト例     |
| `examples/component.test.tsx` | コンポーネントテスト例 |
| `examples/hook.test.ts`       | フックテスト例         |
| `examples/e2e-auth.spec.ts`   | E2E 認証テスト例       |

#### 品質保証テスト

| ファイル                           | 説明                             |
| ---------------------------------- | -------------------------------- |
| `examples/smoke.test.ts`           | スモークテスト例                 |
| `examples/integration.test.ts`     | 統合テスト例                     |
| `examples/regression-auth.spec.ts` | リグレッションテスト例           |
| `examples/visual.spec.ts`          | ビジュアルリグレッションテスト例 |
| `examples/a11y.spec.ts`            | アクセシビリティテスト例         |

#### 高度なテスト

| ファイル                          | 説明                                     |
| --------------------------------- | ---------------------------------------- |
| `examples/contract.test.ts`       | API契約テスト例                          |
| `examples/snapshot.test.tsx`      | スナップショットテスト例                 |
| `examples/property-based.test.ts` | Property-basedテスト例（fast-check使用） |
| `examples/mutation.config.js`     | ミューテーションテスト設定（Stryker）    |

#### パフォーマンス・負荷テスト

| ファイル                       | 説明                                      |
| ------------------------------ | ----------------------------------------- |
| `examples/performance.spec.ts` | パフォーマンステスト例（Core Web Vitals） |
| `examples/load.test.ts`        | 負荷テスト例（k6/Artillery設定含む）      |

#### セキュリティ・インフラテスト

| ファイル                          | 説明                                          |
| --------------------------------- | --------------------------------------------- |
| `examples/security.test.ts`       | セキュリティテスト例                          |
| `examples/database.test.ts`       | データベーステスト例（マイグレーション・RLS） |
| `examples/edge-functions.test.ts` | Edge Functionsテスト例（Deno/Jest）           |
| `examples/api.test.ts`            | REST APIエンドポイントテスト例                |

#### 国際化・SSRテスト

| ファイル                         | 説明                         |
| -------------------------------- | ---------------------------- |
| `examples/i18n.test.tsx`         | 国際化テスト例               |
| `examples/ssr-hydration.spec.ts` | SSR/ハイドレーションテスト例 |

## Related Commands

| コマンド               | 説明                             |
| ---------------------- | -------------------------------- |
| `/setup-ci`            | CI/CD ワークフロー設定           |
| `/setup-husky`         | Git hooks 設定（テスト実行含む） |
| `/test-coverage-trend` | カバレッジ推移の確認             |
| `/pre-pr-checklist`    | PR 作成前チェック                |

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

### A11y テストの特定ルール無視

```typescript
const results = await new AxeBuilder({ page }).exclude('#dynamic-content').disableRules(['color-contrast']).analyze();
```
