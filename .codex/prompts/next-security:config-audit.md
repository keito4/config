# `next-security:config-audit`

Next.js の設定・ミドルウェア・ビルド出力を静的に点検し、ヘッダーや CSP、公開範囲が適切かを確認するコマンド。

## 目的

- `next.config.{js,ts}` / `middleware.{js,ts}` / `app/(api|routes)` の設定に漏れがないか確認
- HSTS, CSP, Permissions-Policy 等のセキュリティヘッダーが導入済みであることを保証
- 画像ホワイトリスト・環境変数公開設定・ビルド警告を棚卸し

## 必要権限と前提

- リポジトリ read 権限のみ（設定ファイルを閲覧）
- `.env` の中身は不要。公開環境に影響する変更は行わない
- `npm --prefix next run lint|type-check|build` を実行できる CI 相当の権限
- Middleware 変更有無を確認するため `git status -sb` を参照（read-only）

## 実行手順

1. **設定ファイル静的確認**
   - `rg -n "headers" next/next.config.*`
   - `rg -n "poweredByHeader" next/next.config.*`
   - `rg -n "images:" next/next.config.*`
   - `rg -n "env" next/next.config.*`
   - `rg -n "middleware" next/app -g "middleware.{js,ts}"`
2. **セキュリティヘッダー**
   - `next.config.*` の `headers()` 戻り値に以下が含まれるか確認
     - `Strict-Transport-Security`
     - `X-Content-Type-Options`
     - `X-Frame-Options`
     - `Referrer-Policy`
     - `Permissions-Policy`
     - `Content-Security-Policy`（`nonce` / `sha` を Layout へ受け渡し）
3. **CSP / Middleware**
   - `next-safe-middleware` / `helmet` の使用状況を確認
   - `config.matcher` が保護対象 Route を網羅しているかチェック
4. **画像・外部リソース**
   - `images.domains` / `remotePatterns` / `experimental.images.allowFutureImage`
   - `font-src`, `connect-src` など外部ドメイン列挙の最小化
5. **ビルド検証**
   - `npm --prefix next run lint`
   - `npm --prefix next run type-check`
   - `npm --prefix next run build`
   - 警告/エラー、`next build` の `Size Limits` などを記録
6. **環境変数公開確認**
   - `rg -n "process\.env" next/ -g "*.ts"` で `NEXT_PUBLIC_` が適切か確認
   - `next.config.*` の `env` に秘匿情報が含まれていないか確認

## 期待アウトプット

- セキュリティヘッダーの有無一覧
- CSP の `default-src` / `script-src` / `connect-src` サマリ
- 画像/外部リソース許可リスト
- lint/type-check/build の結果（Pass/Fail + 警告）
- 改善アクション（例: Permissions-Policy 追加、CSP tighten）

## レポートテンプレ

```
### next-security:config-audit

- headers(): HSTS / X-CTO / XFO / Referrer OK, Permissions-Policy missing
- CSP: default-src 'self'; script-src 'self' 'nonce-...'; connect-src に *.vercel.app を追記予定
- middleware: next-safe-middleware + custom matcher [/dashboard/:path*] ✅
- build: lint ✔ / type-check ✔ / build ✔ (warnings 0)
- env: NEXT_PUBLIC_API_BASE ← 公開 API のみ。秘密情報なし

**Action**
1. Add Permissions-Policy (camera=(), geolocation=())
2. Restrict images.remotePatterns to CDN only
```
