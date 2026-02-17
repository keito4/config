# セットアップガイド

全プロジェクト種別に適用すべき品質ゲートとセットアップ手順の統合ガイド。
[CLAUDE.md](../../CLAUDE.md) の品質基準に基づく。

---

## 1. 共通品質ゲート（全プロジェクト必須）

| 品質ゲート   | 基準                                                |
| ------------ | --------------------------------------------------- |
| Unit テスト  | 全プロジェクトで導入必須                            |
| カバレッジ   | 70%+ (lines / branches / functions / statements)    |
| Lint         | Error=Fail、`--max-warnings 0`                      |
| Format 検証  | CI で `format:check` を実行、Auto-fix 無効時は Fail |
| CI/CD        | Lint → Test → Build → SCA → Deploy                  |
| Git hooks    | husky + commitlint + lint-staged（または lefthook） |
| CLAUDE.md    | 技術スタック・テスト戦略・デプロイ先を記載          |
| SAST         | Critical 検知で Fail                                |
| DevContainer | `ghcr.io/keito4/config-base:latest` ベース          |

### 共通コマンド

| コマンド                    | 用途                                            |
| --------------------------- | ----------------------------------------------- |
| `/setup-husky`              | husky + lint-staged + commitlint の最小構成導入 |
| `/setup-ci`                 | CI/CD ワークフローの雛形作成                    |
| `/setup-new-repo`           | 新規リポジトリの初期セットアップ一式            |
| `/config-base-sync-update`  | DevContainer ベースイメージを最新版に更新       |
| `/config-base-sync-check`   | 現在のベースイメージバージョンを確認            |
| `/security-credential-scan` | 認証情報の漏洩スキャン                          |
| `/code-complexity-check`    | コード複雑度チェック                            |
| `/dependency-health-check`  | 依存パッケージの健全性チェック                  |

---

## 2. SPA (React + Vite)

### テスト環境（Vitest）

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom @vitest/coverage-v8 @vitejs/plugin-react
```

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      thresholds: { lines: 70, branches: 70, functions: 70, statements: 70 },
    },
  },
});
```

### ESLint + Prettier

```bash
npm install -D eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh eslint-config-prettier prettier
```

### CI/CD

```
Lint → Format Check → Test (with coverage) → Build
```

**参考**: `/setup-ci` コマンドで雛形を生成可能。

### husky + commitlint

**参考**: `/setup-husky` コマンドで最小構成を導入可能。

### スクリプト

```json
{
  "test": "vitest run",
  "test:watch": "vitest",
  "test:coverage": "vitest run --coverage",
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "format": "prettier --write .",
  "format:check": "prettier --check ."
}
```

---

## 3. npm ライブラリ (CLI)

### テスト環境（Jest + ts-jest）

```bash
pnpm add -D jest @jest/globals ts-jest @types/jest
```

```js
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  coverageThreshold: {
    global: { branches: 70, functions: 70, lines: 70, statements: 70 },
  },
};
```

### commitlint

semantic-release と組み合わせて Conventional Commits を強制する。

```bash
pnpm add -D @commitlint/cli @commitlint/config-conventional
echo 'pnpm commitlint --edit "$1"' > .husky/commit-msg
```

### CI/CD

```yaml
jobs:
  lint:
    steps:
      - run: pnpm lint
      - run: pnpm format:check
  test:
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - run: pnpm test:coverage
  build:
    steps:
      - run: pnpm build
```

### ESLint Flat Config 統一

`.eslintrc.js` と `eslint.config.mjs` が共存している場合、Flat Config (`eslint.config.mjs`) に統一し `.eslintrc.js` を削除する。

### lint-staged

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml}": ["prettier --write"]
}
```

---

## 4. Web アプリ (Next.js)

### テスト環境

2 パターンが確立されている。プロジェクトの技術スタックに応じて選択する。

**パターン A: Jest + Testing Library**

```bash
npm install -D jest @jest/globals jest-environment-jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event @types/jest
```

```js
// jest.config.js
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

```ts
// vitest.config.ts
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

### ESLint Flat Config + Prettier

```bash
npm install -D eslint @eslint/js typescript-eslint eslint-config-prettier prettier
```

### CI/CD パイプライン

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

**発展構成**（ワークフロー分割）:

- `code-quality.yml`: lint + format + typecheck
- `security.yml`: npm audit + CodeQL
- `deploy.yml`: Vercel / その他プラットフォーム

### husky + commitlint + lint-staged

```bash
npm install -D husky @commitlint/cli @commitlint/config-conventional lint-staged
```

```js
// lint-staged.config.js
module.exports = {
  '*.{ts,tsx,js,jsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
  '*.{css,scss}': ['prettier --write'],
};
```

**pre-push hook**:

```bash
npm run typecheck && npm run lint && npm run format:check && npm run test
```

### E2E テスト（Playwright）

```bash
npm install -D @playwright/test
npx playwright install
```

```ts
// playwright.config.ts
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

### Biome 採用プロジェクト

ESLint + Prettier の代わりに Biome を採用する場合も、テスト環境（Vitest 推奨）とカバレッジ閾値 70% は必須。

### スクリプト

```json
{
  "lint": "next lint --max-warnings 0",
  "lint:fix": "next lint --fix",
  "format": "prettier --write .",
  "format:check": "prettier --check ."
}
```

---

## 5. モバイル (Flutter)

### CI カバレッジ閾値強制

```yaml
- name: Check coverage threshold
  run: |
    COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 \
      | grep "lines" | grep -oP '[\d.]+%' | head -1 | tr -d '%')
    if (( $(echo "$COVERAGE < 70" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 70% threshold"
      exit 1
    fi
    echo "Coverage: $COVERAGE%"
```

> 代替: `very_good_cli` の `very_good test --min-coverage 70` も利用可能。

### CI フォーマット検証

```yaml
- name: Format check
  run: dart format --set-exit-if-changed .
```

### commitlint（lefthook）

Flutter プロジェクトは Node.js 非依存の lefthook を推奨。

```bash
brew install lefthook
```

```yaml
# lefthook.yml
commit-msg:
  commands:
    commitlint:
      run: 'echo "{1}" | npx commitlint --edit'

pre-commit:
  commands:
    format:
      run: dart format --set-exit-if-changed .
    analyze:
      run: flutter analyze
```

### Claude Code ワークフロー

config リポジトリの `.github/workflows/claude.yml` をテンプレートとして追加。

### CodeQL / SAST

Dart 向けの CodeQL は限定的だが、依存関係スキャンは有効。

### DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **Features**: `flutter`, `java(17)` — Flutter 固有のため維持
- **postCreateCommand**: `flutter pub get && dart run build_runner build --delete-conflicting-outputs`

---

## 6. モバイル (Android)

### detekt（Kotlin 静的解析）

```kotlin
// build.gradle.kts (ルート)
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.7" apply false
}

// app/build.gradle.kts
plugins {
    id("io.gitlab.arturbosch.detekt")
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom("$rootDir/config/detekt.yml")
}
```

```yaml
# CI
- name: Run detekt
  run: ./gradlew detekt
```

### Kover（カバレッジ 70%）

```kotlin
// app/build.gradle.kts
plugins {
    id("org.jetbrains.kotlinx.kover") version "0.9.1"
}

kover {
    reports {
        verify {
            rule {
                minBound(70)
            }
        }
    }
}
```

```yaml
# CI
- name: Run tests with coverage
  run: ./gradlew koverVerify
- name: Generate coverage report
  run: ./gradlew koverHtmlReport
```

### commitlint（lefthook）

Android プロジェクトは JVM 非依存の lefthook を推奨。

```yaml
# lefthook.yml
commit-msg:
  commands:
    commitlint:
      run: 'echo "{1}" | npx commitlint --edit'
```

### CodeQL

```yaml
- name: Initialize CodeQL
  uses: github/codeql-action/init@v3
  with:
    languages: java-kotlin
- name: Build
  run: ./gradlew assembleDebug
- name: Perform CodeQL Analysis
  uses: github/codeql-action/analyze@v3
```

### DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **Features**: `java(17)` + Gradle — Android 固有のため維持
- **postCreateCommand**: `sdkmanager --install 'platforms;android-35' ...`

---

## 7. デスクトップ拡張 (TS)

### テスト環境（Vitest + Raycast API モック）

```ts
// extensions/<extension>/vitest.config.ts
import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    include: ['src/**/*.test.ts'],
  },
  resolve: {
    alias: {
      // Raycast API をモック化
      '@raycast/api': path.resolve(__dirname, 'src/__mocks__/raycast-api.ts'),
    },
  },
});
```

**各拡張への展開手順**:

1. 各拡張の `package.json` に `vitest` + `@vitest/coverage-v8` を追加
2. `vitest.config.ts` を作成（上記パターンをベースに）
3. `src/__mocks__/raycast-api.ts` を作成
4. ビジネスロジックを純粋関数に分離してテスト対象に

### CI テストステップ

```yaml
- name: Run tests
  run: |
    for dir in extensions/*/; do
      if [ -f "$dir/vitest.config.ts" ]; then
        name=$(basename "$dir")
        echo "Testing $name"
        pnpm --filter "$name" test
      fi
    done
```

### CI lint strict 化

`continue-on-error: true` を削除し、`@raycast/eslint-config` との互換性問題は個別ルール override で解消する。

### lint-staged

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{js,jsx,md,json,yaml,yml}": ["prettier --write"]
}
```

### pre-push hook

```bash
pnpm test && pnpm -r exec tsc --noEmit
```

### DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **Features**: `docker-in-docker` のみ維持（ベースイメージに含まれるものは削除）

---

## 8. CLAUDE.md テンプレート（全プロジェクト共通）

各プロジェクトの CLAUDE.md に含めるべき内容:

- **技術スタック**: 言語・フレームワーク・主要ライブラリのバージョン
- **アーキテクチャ**: レイヤー分離方針、ディレクトリ構成
- **テスト戦略**: フレームワーク選択理由、E2E の有無、モック戦略
- **環境変数**: 必要なキーと管理方法
- **デプロイ先**: Vercel / Firebase / その他
- **品質ゲート**: pre-commit / pre-push の実行内容
- **リリースフロー**: semantic-release / release-please の設定

---

## 9. Claude Code ワークフロー（全プロジェクト共通）

- `claude.yml`: `@claude` メンション対応
- `claude-code-review.yml`: PR 自動レビュー

config リポジトリの `.github/workflows/claude.yml` をテンプレートとして使用。
