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
    "ignore": ["dist", "node_modules", "coverage"]
  }
}
```

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

## CI/CD ワークフロー

**参考**: `/setup-ci` コマンドで雛形を生成可能。

```
Lint → Format Check → Test (with coverage) → Build
```

## husky + commitlint

**参考**: `/setup-husky` コマンドで最小構成を導入可能。

## lint-staged

```js
// lint-staged.config.js
module.exports = {
  '*.{ts,tsx,js,jsx,json,css}': ['biome check --write --no-errors-on-unmatched'],
  '*.{md,yml,yaml}': ['biome format --write --no-errors-on-unmatched'],
};
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

## pnpm セキュリティ設定（supply chain attack 対策）

pnpm を使用する場合は以下を必ず設定する。

**`pnpm-workspace.yaml`**:

```yaml
# 公開から 2 日未満のパッケージをインストール禁止（pnpm v10.16.0+）
minimumReleaseAge: 2880
```

**`.npmrc`**:

```ini
strict-peer-dependencies=true
auto-install-peers=true
audit=true
audit-level=moderate
shamefully-hoist=false
verify-store-integrity=true
```

## 関連ドキュメント

| ドキュメント                                          | 説明                                  |
| ----------------------------------------------------- | ------------------------------------- |
| [ツールカタログ](../tool-catalog.md)                  | 環境×ツールのマトリクス               |
| [MCP サーバーガイド](../mcp-servers-guide.md)         | Linear, Playwright, Supabase 等の連携 |
| [config-base イメージ](../using-config-base-image.md) | DevContainer ベースイメージの詳細     |
