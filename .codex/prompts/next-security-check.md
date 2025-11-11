# Next.js セキュリティチェック

Next.js プロジェクトに対して、依存関係・設定・実装レベルのセキュリティリスクを洗い出すための定型フロー。

## ゴール

- 既知の脆弱性（npm audit / Snyk など）をゼロにするか、リスクと回避策を明記する
- `next.config.{js,ts}` とミドルウェア層で主要ヘッダー・CSP・イメージ許可リストが適切に設定されている
- API Routes / Route Handlers / Server Actions で認可・入力検証・CSRF 対策が実装されている
- 秘匿情報が `env` 経由でクライアントに漏れていない
- ロール/権限ごとのアクセス制御が middleware・API・UI で一貫している

## コマンドプリセット

1. **`next-security:deps-scan`**（権限: read-only + npm install 実行権限）
   - 依存関係の既知脆弱性とバージョン遅延を洗い出す
   - 生成物はログのみ。リポジトリへ書き込みはしない
2. **`next-security:config-audit`**（権限: read-only）
   - `next.config.*`, `middleware.*`, `app/(api|routes)` を静的に確認
   - ヘッダー/CSP/画像ホワイトリスト/環境変数公開範囲を検証
3. **`next-security:authz-review`**（権限: read-only + .env.local 閲覧権限）
   - 認証・認可（RBAC/ABAC）ロジックを確認
   - Role ごとのフロー、Session/Token の有効期限、権限付きリソースの保護状況を検証

> それぞれのコマンドを個別に回せるようにし、必要最低限の権限だけをエージェントに付与する。
> 詳細手順は `.codex/prompts/next-security:*.md` を参照。

## 実行フロー（最低限）

1. **依存関係スキャン**
   - `npm --prefix next audit --omit dev`
   - `npx --yes @nodesecurity/eslint-plugin-security --version` 等のプラグインが最新か確認
   - `npm outdated --prefix next next react react-dom next-auth` で主要パッケージの遅延を把握
2. **ビルド時チェック**
   - `npm --prefix next run lint`
   - `npm --prefix next run type-check`
   - `npm --prefix next run build`（`--no-lint` を付けない）で警告を確認
3. **ミドルウェア/設定確認**
   - `next.config.*` と `middleware.{js,ts}` を開いて、以下が揃っているか確認
     - `headers()` に HSTS / X-Content-Type-Options / X-Frame-Options / Referrer-Policy
     - `Content-Security-Policy`（CSP）を `next-safe-middleware` などで集中管理し、`script-src` で `nonce` or `sha` を利用
     - `images.domains` / `remotePatterns` で外部イメージを最小限定
     - `env` でクライアントへ公開しているキーが非機密か
4. **実装確認ポイント**
   - App Router: Route Handler / Server Action で `cache: 'no-store'` または `revalidate` の意図確認
   - API Routes: 認証ミドルウェア（NextAuth, Lucia など）で `getServerSession` を必須化、レートリミット（Upstash, KV）を適用
   - フォーム: `next/headers`＋`csrfToken`、`SameSite=strict` Cookie 設定
   - SSR/ISR: 外部入力を `zod`, `valibot`, `Yup` などでサニタイズ後にテンプレートへ渡す
   - クライアント: `dangerouslySetInnerHTML` 禁止 or sanitize-html, `next/script` は `strategy="afterInteractive"` 以上＋`nonce`

## 詳細チェックリスト

- **依存関係**
  - `next`, `react`, `react-dom`, `next-auth`, `next-safe-middleware` などの minor 以上の遅れを Issue 化
  - `dependencies` に dev-only ツールが紛れていないか
- **設定ファイル**
  - `productionBrowserSourceMaps` を false にしてソース漏えい防止
  - `compress` 有効化で gzip/brotli、`poweredByHeader: false`
  - `eslint.ignoreDuringBuilds` は極力使わない
- **ヘッダー/CSP**
  - 必須: `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`
  - `Content-Security-Policy` で `frame-ancestors 'none'`、`connect-src` に外部 API を列挙
  - `next-safe-middleware` や `helmet` を middleware で適用し、`nonce` を `request` コンテキストから Layout へ伝搬
- **API & データ**
  - `POST` 以外で状態変更しない、`mutate` 系は `anti-CSRF token` を確認
  - Prisma/ORM クエリに raw SQL を渡さない、`where` 条件はユーザ入力を直接渡さない
  - Upload ルートはファイルサイズ・拡張子・MIME を検証し S3 署名 URL を短期限に設定
- **認証/セッション**
  - NextAuth: `NEXTAUTH_SECRET` 設定済み、`jwt.maxAge` と `session.strategy` の要件一致
  - Middleware で `auth()` を呼び、`config.matcher` で保護パスを網羅
  - Cookie: `secure`, `httpOnly`, `sameSite=strict`、Edge Runtime でも暗号化
- **権限/アクセス制御**
  - ロール × リソースのマトリクスを用意し、Route Handler/API/ページごとに必要権限を明記
  - `next-auth` / `auth.js` の `callbacks.session` / `callbacks.jwt` でロール情報を必ず付与
  - middleware で `role` / `permission` を判定し、Route Group 単位で `config.matcher` に含める
  - サーバーコンポーネント/Server Actions でも `assertPermission` などのガードを実行
  - クライアント側の UI 非表示だけに頼らず、API レベルで拒否（403）する
- **ビルド/デプロイ**
  - `next build` 結果で警告がないことをスクショ or log として残す
  - Vercel/Node サーバで `NODE_ENV=production` を強制
  - `.env*` を gitignore 済みか再確認、`NEXT_PUBLIC_*` の値を棚卸し

## レポートテンプレ

```
## Summary
- npm audit: 0 critical / 1 high (axios CVE-2023-??? → 対応中)
- next.config.js: CSP + HSTS 適用済み、Permissions-Policy 追加予定
- API Routes: /api/internal/* に未認証アクセス可能 → middleware で保護予定

## Action Items
1. Upgrade axios 1.6.0 → 1.7.4 (high)
2. Add CSRF token + SameSite=strict for POST /api/forms
3. Extend middleware matcher to /dashboard/*
```

## 参考コマンド

### `next-security:deps-scan`

```
npm --prefix next audit --omit dev
npm --prefix next outdated
```

### `next-security:config-audit`

```
npm --prefix next run lint
npm --prefix next run type-check
npm --prefix next run build
```

### `next-security:authz-review`

```
rg -n "auth" next/
rg -n "role" next/
rg -n "permission" next/
cat next/app/middleware.ts
cat next/app/api/**/route.ts
```

## Follow-up

- 重大/高リスクが残る場合は Issue に `severity/security` ラベルで登録し ETA を記載
- CSP や middleware 変更は必ず `next build && next start` で E2E 動作検証
- 依存更新を行った場合は `npm --prefix next run test`（もしくは Playwright/E2E）を実行
