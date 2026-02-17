# デスクトップ拡張 (TS) セットアップガイド

## テスト環境（Vitest + Raycast API モック）

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

> **Raycast API モック**: `@raycast/api` を `resolve.alias` でモックファイルに差し替えるパターンが有効。

**各拡張への展開手順**:

1. 各拡張の `package.json` に `vitest` + `@vitest/coverage-v8` を追加
2. `vitest.config.ts` を作成（上記パターンをベースに）
3. `src/__mocks__/raycast-api.ts` を作成
4. ビジネスロジックを純粋関数に分離してテスト対象に

## CI テストステップ

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

## CI lint strict 化

`continue-on-error: true` を削除し、`@raycast/eslint-config` との互換性問題は個別ルール override で解消する。

**段階的アプローチ**:

1. ローカルで `pnpm lint` を実行し、現在のエラーを特定
2. `@raycast/eslint-config` との互換性問題を解消（必要に応じて個別ルールを override）
3. CI から `continue-on-error: true` を削除

## lint-staged に ESLint 追加

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{js,jsx,md,json,yaml,yml}": ["prettier --write"]
}
```

## pre-push hook

```bash
pnpm test && pnpm -r exec tsc --noEmit
```

## Claude Code ワークフロー

config リポジトリの `.github/workflows/claude.yml` をテンプレートとして追加。

## CLAUDE.md

**含めるべき内容**:

- **構成**: pnpm workspaces monorepo（`extensions/*`）
- **拡張一覧**: 各拡張の名前と用途
- **Raycast API**: 各拡張が `@raycast/api` + `@raycast/utils` に依存
- **ESLint**: `@raycast/eslint-config` を各拡張で継承
- **commitlint**: `subject-case` を無効化（日本語コミットメッセージ対応）
- **テスト戦略**: Raycast API モック + ロジック層分離パターン
- **リリース**: 日付ベースバージョニング（`v{YYYY.MM.DD}-{short-sha}`）

## DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **冗長 Features の削除**: ベースイメージに含まれるもの（github-cli, pnpm, jq-likes）は削除
- **残すべき Features**: `docker-in-docker`（プロジェクト固有）
