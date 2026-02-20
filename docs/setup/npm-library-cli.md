# npm ライブラリ (CLI) セットアップガイド

## commitlint

semantic-release と組み合わせて Conventional Commits を強制する。

```bash
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

**設定ファイル** (`commitlint.config.js`):

```js
export default { extends: ['@commitlint/config-conventional'] };
```

**husky hook 追加**:

```bash
echo 'pnpm commitlint --edit "$1"' > .husky/commit-msg
```

**参考**: `/setup-husky` コマンドで commitlint を含む構成を導入可能。

## カバレッジ閾値 70%

```js
// jest.config.js
coverageThreshold: {
  global: { branches: 70, functions: 70, lines: 70, statements: 70 },
},
```

閾値が低い場合は +10% ずつ段階的に引き上げる。

## CI に `format:check` ステップ追加

```yaml
- name: Format check
  run: pnpm format:check
```

## lint-staged

```bash
pnpm add -D lint-staged
```

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml}": ["prettier --write"]
}
```

**`.husky/pre-commit` を更新**:

```bash
pnpm exec lint-staged
```

## CLAUDE.md

**含めるべき内容**:

- **用途**: ライブラリ / CLI の概要
- **技術スタック**: TypeScript バージョン、主要依存パッケージ
- **テスト戦略**: テストフレームワーク、ESM モック化の要否
- **リリースフロー**: semantic-release の設定と対象ブランチ
- **ビルド**: `tsc` → `dist/` の設定、declaration の有無
- **公開設定**: `bin`、`files`、`exports` の構成

## ESLint Flat Config 統一

`.eslintrc.js` と `eslint.config.mjs` が共存している場合、Flat Config (`eslint.config.mjs`) に統一し `.eslintrc.js` を削除する。

**手順**:

1. `.eslintrc.js` の内容を確認し、`eslint.config.mjs` に未反映のルールがないか検証
2. `tsconfig.eslint.json`（`.eslintrc.js` 用）の参照を確認
3. `.eslintrc.js` と不要な `tsconfig.eslint.json` を削除
4. `pnpm lint` で正常動作を確認

## DevContainer

- **ベースイメージ**: `ghcr.io/keito4/config-base:latest`
- **冗長 Features の削除**: ベースイメージに含まれるもの（node, gh 等）は更新後に削除を検討

## 関連ドキュメント

| ドキュメント                                          | 説明                              |
| ----------------------------------------------------- | --------------------------------- |
| [ツールカタログ](../tool-catalog.md)                  | 環境×ツールのマトリクス           |
| [config-base イメージ](../using-config-base-image.md) | DevContainer ベースイメージの詳細 |
