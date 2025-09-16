Husky + lint-staged + commitlint 最小構成

コミット前に軽量な自動整形と静的チェックを行い、プッシュ前とCIで重い検証を実行します。

方針
• pre-commit: ステージ済みファイルに対して ESLint 自動修正と Prettier 整形を高速実行
• pre-push: 型チェックとテストを実行
• commit-msg: Conventional Commits を commitlint で検証
• npm --prefix next で一貫して next/ の依存を使用

⸻

セットアップ

npm i -D husky lint-staged @commitlint/cli @commitlint/config-conventional
npm pkg set scripts.prepare="husky"
npm run prepare
npx husky add .husky/pre-commit "npx lint-staged"
npx husky add .husky/commit-msg "npx commitlint --edit \$1"
npx husky add .husky/pre-push "npm --prefix next run type-check && npm --prefix next run test:ci"

⸻

必要な npm scripts（next/package.json）

{
"scripts": {
"type-check": "tsc --noEmit",
"lint": "eslint .",
"format": "prettier --write .",
"format:check": "prettier --check .",
"test:ci": "jest --ci --runInBand"
}
}

⸻

設定ファイル

.lintstagedrc.json（リポジトリルート）

{
"next/**/\*.{ts,tsx}": [
"npm --prefix next exec eslint --cache --cache-location .cache/eslint --max-warnings=0 --fix",
"npm --prefix next exec prettier --write"
],
"next/**/\*.{js,jsx,json,md,css,scss}": [
"npm --prefix next exec prettier --write"
]
}

.commitlintrc.json（リポジトリルート）

{
"extends": ["@commitlint/config-conventional"]
}

.eslintignore（任意、next/に配置）

node_modules
.next
dist
coverage
public

.prettierignore（任意、next/に配置）

node_modules
.next
dist
coverage
build

package.json（任意、ルート。Nodeバージョン固定）

{
"engines": {
"node": ">=20 <23"
}
}

.nvmrc（任意、ルート）

20

⸻

CI 例（GitHub Actions）

.github/workflows/ci.yml

name: CI
on:
push:
branches: [main]
pull_request:
jobs:
node:
runs-on: ubuntu-latest
steps: - uses: actions/checkout@v4 - uses: actions/setup-node@v4
with:
node-version: 20
cache: npm - run: npm ci - run: npm ci
working-directory: next - run: npm run type-check
working-directory: next - run: npm run lint
working-directory: next - run: npm run format:check
working-directory: next - run: npm run test:ci
working-directory: next

⸻

トラブルシューティング

フックの確認

git config core.hooksPath

Husky の再初期化

rm -rf .husky
npm run prepare
npx husky add .husky/pre-commit "npx lint-staged"
npx husky add .husky/commit-msg "npx commitlint --edit \$1"
npx husky add .husky/pre-push "npm --prefix next run type-check && npm --prefix next run test:ci"

一時的にフックをスキップ

git commit --no-verify -m "urgent: emergency fix"
