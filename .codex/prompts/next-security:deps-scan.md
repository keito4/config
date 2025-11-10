# `next-security:deps-scan`

Next.js プロジェクトの依存関係に既知の脆弱性やサポート外バージョンが含まれていないかを、最小権限で洗い出すコマンド。

## 目的

- `next`, `react`, `next-auth` など基幹パッケージの脆弱性・EOL 状態を把握
- セキュリティ関連の ESLint/型チェッカープラグインが最新であることを確認
- 危険度の高い項目を Issue/PR に落とし込み、回避策と ETA を明記

## 必要権限と前提

- リポジトリ read 権限
- `next/` ディレクトリで `npm audit` / `npm outdated` を実行できるローカル実行権限
- `node_modules` を書き換えずに済むよう `npm install` は行わない（必要なら sandbox 環境を使う）
- 実行前に `node -v` / `npm -v` を記録し、結果に添付

## 実行手順

1. **環境確認**
   - `node -v && npm -v`
2. **既知脆弱性の確認**
   - `npm --prefix next audit --omit dev`
   - 重大度別トータルと影響パッケージ一覧をメモ
3. **主要パッケージの遅延調査**
   - `npm outdated --prefix next next react react-dom next-auth next-safe-middleware`
   - `Target`, `Current`, `Latest` を表で整理
4. **セキュリティ lint 依存の健全性**
   - `npm --prefix next list --depth=0 | rg -E "eslint|security|helmet|safe"`
   - `npx --yes npm-check-updates --target minor --cwd next --filter "eslint*|@next/eslint-plugin-next"`
5. **結果整理**
   - クリティカル/ハイ優先度 → 必須対応
   - Med/Low → Issue backlog、回避策の有無を記述

## 期待アウトプット

- 重大度ごとの件数表
- 影響パッケージ・CVE・回避策・対応 ETA のリスト
- npm audit / outdated ログ（要約で可）
- 対応不要と判断した場合の理由（例: devDependency のみ、Feature flag 下など）

## レポートテンプレ

```
### next-security:deps-scan
Node 20.11 / npm 10.5

| Severity | Count | Packages (example) |
|----------|-------|--------------------|
| Critical | 0     | -                  |
| High     | 1     | axios@1.6.0 (CVE-2023-XXXX) |
| Moderate | 2     | postcss@8.4.5, braces@3.0.2 |

**Upgrade plan**
- [ ] axios 1.6.0 → 1.7.4 (PR #123 ETA 2024-05-01)
- [ ] next 14.1.0 → 14.2.3 （blocked: storybook plugin）

```
