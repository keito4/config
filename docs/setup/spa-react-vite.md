# SPA (React + Vite) セットアップガイド

## テスト環境（Vitest）

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom @vitest/coverage-v8 @vitejs/plugin-react
```

> 注: `@vitejs/plugin-react` はテスト環境（jsdom）で React コンポーネントをレンダリングするために必要。

**設定例** (`vitest.config.ts`):

```ts
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
  resolve: {
    alias: { '@': '.' },
  },
});
```

> `resolve.alias` は `tsconfig.json` の `paths: { "@/*": ["./*"] }` と合わせる。

**スクリプト**:

```json
{
  "test": "vitest run",
  "test:watch": "vitest",
  "test:coverage": "vitest run --coverage"
}
```

## ESLint + Prettier

```bash
npm install -D eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh eslint-config-prettier
npm install -D prettier
```

**スクリプト**:

```json
{
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "format": "prettier --write .",
  "format:check": "prettier --check ."
}
```

## CI/CD ワークフロー

**参考**: `/setup-ci` コマンドで雛形を生成可能。

```
Lint → Format Check → Test (with coverage) → Build
```

## husky + commitlint

**参考**: `/setup-husky` コマンドで最小構成を導入可能。

## lint-staged

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml}": ["prettier --write"]
}
```

## CLAUDE.md

**含めるべき内容**:

- **用途**: アプリケーションの概要
- **技術スタック**: React / Vite / TypeScript のバージョン、主要ライブラリ
- **環境変数**: 必要な API キーと管理方法（`.env.local`）
- **コンポーネント設計**: ディレクトリ構成と設計方針
- **パスエイリアス**: `@/*` の解決先

## DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
