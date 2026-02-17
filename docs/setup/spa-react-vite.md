# SPA (React + Vite) セットアップガイド

## 現状サマリー

[docs/tool-catalog.md](../tool-catalog.md) セクション 4.1 および `ai_topic_decomposer` リポジトリの実態調査に基づく。

- [x] React 19.1.0 + Vite 6.3.5 + TypeScript 5.7.3 でプロジェクト構成済み
- [x] DevContainer 設定あり（ベースイメージ 1.0.13、Features なし）
- [x] tsconfig.json で `strict: true` + `jsx: "react-jsx"` 設定済み
- [x] VS Code 拡張に ESLint・Prettier・TypeScript を指定済み
- [ ] Unit テスト環境（未設定）
- [ ] E2E テスト環境（未設定）
- [ ] ESLint 設定ファイル（VS Code 拡張は指定済みだが設定ファイルがなく機能していない）
- [ ] Prettier 設定ファイル（VS Code 拡張は指定済みだがデフォルト設定のみ）
- [ ] CI/CD ワークフロー（`.github/workflows/` 未作成）
- [ ] husky + commitlint（未設定）
- [ ] CLAUDE.md（未作成、`.claude/settings.local.json` のみ存在）
- [ ] SAST / CodeQL（未設定）

**現在の品質ゲート達成率: 最も低い（ビルド環境のみ整備済み）**

## セットアップ項目

### 優先度: 高

#### 1. テスト環境構築（Vitest）

**何を**: Vitest + Testing Library でユニットテスト環境を構築する。

**なぜ**: TDD ベースライン（70%+ カバレッジ）を満たすための前提条件。テストがなければ品質保証ができない。

**参考コマンド**:

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom @vitest/coverage-v8 @vitejs/plugin-react
```

> 注: 現在の `package.json` には `@vitejs/plugin-react` が含まれていない。テスト環境（jsdom）で React コンポーネントをレンダリングするために追加が必要。

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

> `resolve.alias` は既存の `tsconfig.json` の `paths: { "@/*": ["./*"] }` と合わせる。

**package.json に追加するスクリプト**:

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  }
}
```

#### 2. ESLint + Prettier 導入

**何を**: ESLint（Flat Config）+ Prettier でコード品質とフォーマットを統一する。

**なぜ**: VS Code 拡張（`dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`）は `devcontainer.json` に指定されているが、設定ファイルが存在しないため実質的に機能していない。

**参考コマンド**:

```bash
npm install -D eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh eslint-config-prettier
npm install -D prettier
```

**package.json に追加するスクリプト**:

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  }
}
```

> 注: 現在の `devcontainer.json` に `bradlc.vscode-tailwindcss` 拡張が含まれているが、Tailwind CSS は使用していない。不要なら削除を検討。

#### 3. CI/CD ワークフロー作成

**何を**: GitHub Actions で Lint → Test → Build パイプラインを構築する。

**なぜ**: `.github/workflows/` ディレクトリ自体が存在しない。CI がなければ品質ゲートの自動検証ができない。

**参考**: `/setup-ci` コマンドで雛形を生成可能。

**最小ステージ**:

```
Lint → Format Check → Test (with coverage) → Build
```

#### 4. CLAUDE.md 作成

**何を**: プロジェクト固有の開発コンテキストを CLAUDE.md に記載する。

**含めるべき内容**（実リポジトリの構成に基づく）:

- **用途**: AI トピック分解・ナレッジマップ生成アプリ
- **技術スタック**: React 19, Vite 6, TypeScript 5.7, @google/genai (Gemini API), D3.js
- **環境変数**: `GEMINI_API_KEY`（`.env.local` で管理、vite.config.ts で `process.env` に注入）
- **コンポーネント設計**: `components/` 配下に 18 ファイル（D3 グラフ、モーダル等）
- **パスエイリアス**: `@/*` → `./*`

### 優先度: 中

#### 5. husky + commitlint 導入

**何を**: Git hooks で Conventional Commits を強制する。

**なぜ**: コミットメッセージの統一により、自動リリースノート生成やセマンティックバージョニングが可能になる。

**参考**: `/setup-husky` コマンドで最小構成を導入可能。

#### 6. lint-staged 設定

**何を**: コミット時にステージされたファイルのみ lint/format を実行する。

**参考設定** (`.lintstagedrc`):

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml}": ["prettier --write"]
}
```

### 優先度: 低

#### 7. ベースイメージ更新（1.0.13 → latest）

**何を**: DevContainer のベースイメージを最新版に更新する。

**なぜ**: AI CLI ツールやセキュリティパッチが大幅に遅れている（1.0.13 → 1.58.0+）。

**参考**: `/config-base-sync-update` コマンドで更新 + PR 作成が可能。

## DevContainer 最適化

- **ベースイメージ**: `ghcr.io/keito4/config-base:1.0.13` → `ghcr.io/keito4/config-base:latest`
- **既存 Features**: なし（`"features": {}`）
- **VS Code 拡張の整理**: `bradlc.vscode-tailwindcss` は未使用なら削除検討
