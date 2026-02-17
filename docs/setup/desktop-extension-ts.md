# デスクトップ拡張 (TS) セットアップガイド

## 現状サマリー

[docs/tool-catalog.md](../tool-catalog.md) セクション 4.1 および代表リポジトリの実態調査に基づく。

- [x] TypeScript 5.7.3 + Raycast API 構成済み
- [x] pnpm 10.28.1 workspaces monorepo（8 拡張）
- [x] ESLint 設定あり（各拡張で `@raycast/eslint-config` を継承）
- [x] Prettier 3.5.3 設定あり (`.prettierrc.json`: singleQuote: true, printWidth: 120)
- [x] husky 9 + commitlint 20 導入済み（`subject-case` 無効化で日本語対応）
- [x] lint-staged 導入済み（Prettier のみ: `prettier --write`）
- [x] CI ワークフロー（Format → Lint → Type check → Build）
- [x] Release ワークフロー（日付ベースバージョニング + zip パッケージング）
- [x] 1 拡張に Vitest テスト環境あり（Raycast API モック実装の参考例）
- [ ] テスト環境（他の拡張で未設定）
- [ ] CI の lint に `continue-on-error: true`（`@raycast/eslint-config` 互換性問題のため）
- [ ] lint-staged に ESLint 未追加
- [ ] pre-push hook（未設定）
- [ ] claude.yml ワークフロー（未追加）
- [ ] CLAUDE.md（未作成）

**現在の品質ゲート達成率: 中程度（Git hooks は整備済み、テストと CI の厳格化が不足）**

## セットアップ項目

### 優先度: 高

#### 1. テスト環境を全拡張に展開

**何を**: 既存の Vitest 設定を参考に、他の拡張にもテスト環境を構築する。

**なぜ**: TDD ベースライン（70%+ カバレッジ）を満たすための前提条件。1 拡張に参考実装があるため、パターンを横展開できる。

**既存実装（参考パターン）**:

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

#### 2. CI にテストステップを追加

**何を**: CI パイプラインにテスト実行ステップを追加する。

**なぜ**: テスト環境を構築しても CI で実行しなければ品質ゲートとして機能しない。

**ci.yml に追加**:

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

#### 3. CI の lint `continue-on-error` 解除

**何を**: CI の lint ステップから `continue-on-error: true` を削除する。

**なぜ**: 現在のコメントに `# ESLint compatibility issue with @raycast/eslint-config` とあるが、この問題を解消した上で strict モードに移行する必要がある。

**段階的アプローチ**:

1. ローカルで `pnpm lint` を実行し、現在のエラーを特定
2. `@raycast/eslint-config` との互換性問題を解消（必要に応じて個別ルールを override）
3. CI から `continue-on-error: true` を削除

### 優先度: 中

#### 4. lint-staged に ESLint を追加

**何を**: 現在の `.lintstagedrc.json` に ESLint を追加する。

**現在の設定**:

```json
{
  "**/*.{js,jsx,ts,tsx,md,json,yaml,yml}": ["prettier --write"]
}
```

**変更後**:

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{js,jsx,md,json,yaml,yml}": ["prettier --write"]
}
```

#### 5. pre-push hook 追加

**何を**: husky の pre-push hook でテストと型チェックを実行する。

**設定**:

```bash
echo 'pnpm test && pnpm -r exec tsc --noEmit' > .husky/pre-push
```

#### 6. claude.yml ワークフロー追加

**何を**: `@claude` メンション対応の GitHub Actions ワークフローを追加する。

**参考**: config リポジトリの `.github/workflows/claude.yml` をテンプレートとして使用。

#### 7. CLAUDE.md 作成

**何を**: プロジェクト固有の開発コンテキストを CLAUDE.md に記載する。

**含めるべき内容**:

- **構成**: pnpm workspaces monorepo（`extensions/*`）
- **拡張一覧**: 各拡張の名前と用途
- **Raycast API**: 各拡張が `@raycast/api` + `@raycast/utils` に依存
- **ESLint**: `@raycast/eslint-config` を各拡張で継承
- **commitlint**: `subject-case` を無効化（日本語コミットメッセージ対応）
- **テスト戦略**: Raycast API モック + ロジック層分離パターン
- **リリース**: 日付ベースバージョニング（`v{YYYY.MM.DD}-{short-sha}`）

### 優先度: 低

#### 8. DevContainer 冗長 Features の削除

**何を**: ベースイメージに含まれるツールと重複する Features を削除する。

**現在の Features**（4 項目）:

```json
"features": {
  "ghcr.io/devcontainers/features/github-cli:1": {},    // ベースイメージに含まれる
  "ghcr.io/devcontainers/features/docker-in-docker:2": {},// 維持（プロジェクト固有）
  "ghcr.io/devcontainers-extra/features/pnpm:2": {},     // ベースイメージに含まれる
  "ghcr.io/eitsupi/devcontainer-features/jq-likes:2": {} // ベースイメージに含まれる
}
```

**削除候補**: github-cli, pnpm, jq-likes（3 項目）
**残すべき Features**: docker-in-docker

#### 9. ベースイメージ更新（1.58.0 → latest）

**何を**: DevContainer のベースイメージを最新版に更新する。

**参考**: `/config-base-sync-update` コマンドで更新 + PR 作成が可能。

## DevContainer 最適化

- **ベースイメージ**: `ghcr.io/keito4/config-base:1.58.0` → `ghcr.io/keito4/config-base:latest`
- **削除対象 Features**: ベースイメージと重複する 3 項目（github-cli, pnpm, jq-likes）
- **残すべき Features**: `docker-in-docker` — プロジェクト固有の要件
