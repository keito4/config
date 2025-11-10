# `next-security:authz-review`

Next.js (App Router/Pages) の認証・認可実装を棚卸しし、ロール/権限ごとのアクセス制御とセッション設定が適切かを検証するコマンド。

## 目的

- RBAC/ABAC の要件と実装の乖離を検出
- API Routes / Route Handlers / Server Actions が適切に保護されているか確認
- セッション/Cookie/Token の安全設定（期限、SameSite、暗号化）を担保
- UI だけでなくサーバー側で権限を enforce しているかを評価

## 必要権限と前提

- リポジトリ read 権限
- `.env` や `NEXTAUTH_SECRET` など機密値を閲覧する場合は、最小限の view 権限のみ付与（書き込み不可）
- 認証プロバイダ（NextAuth, Lucia 等）の設定ファイルへアクセス可能であること
- 実ユーザー/ロール定義がどこに記録されているか（DB, config, code）を把握

## 実行手順

1. **認証基盤の特定**
   - `rg -n "NextAuth" -g "*.ts" next/`
   - `rg -n "auth(" next/`
   - `rg -n "getServerSession" next/app`
2. **ロール/権限のデータフロー調査**
   - `rg -n "role" next/`
   - `rg -n "permission" next/`
   - `auth.ts` / `lib/auth` / `middleware.ts` を確認し、`session.user.role` などの形を特定
3. **Middleware でのガード**
   - `middleware.{js,ts}` の `config.matcher` に保護対象パスが含まれているか
   - 例: `/dashboard/:path*`, `/api/internal/:path*`
4. **API / Route Handler 点検**
   - `cat next/app/api/**/route.ts | rg -n "auth|session|role"`
   - 各 Route が `getServerSession`, `assertPermission`, `rateLimit` を実行しているか
   - 状態変更系は `POST` のみに限定されているか
5. **Server Actions / RSC**
   - `rg -n "\"use server\"" next/`
   - 重要アクションで `assertPermission(user, "resource:action")` のようなガードがあるか確認
6. **Cookie / セッション設定**
   - NextAuth: `NEXTAUTH_SECRET`, `session.strategy`, `session.maxAge`
   - Cookie オプション: `secure`, `httpOnly`, `sameSite=strict`, `partitioned`
   - CSRF: `getCsrfToken` / `anti-CSRF token` の存在
7. **UI と API の整合性**
   - クライアント側でボタン非表示にするだけでなく、API 側でも 403 が返るか
   - `role` 切替用の Feature flag がある場合、その制御フローを図解

## 期待アウトプット

- ロール × リソース表（例: Admin, Editor, Viewer）
- 主要エンドポイントごとの認可方法（middleware／Server Action／API Route）
- セッション/Cookie 設定の要約
- ギャップと是正策（例: `/api/internal/export` に認証ガードなし → middleware 追加）

## レポートテンプレ

```
### next-security:authz-review

| Resource              | Admin | Editor | Viewer | Guard                                    |
|-----------------------|-------|--------|--------|------------------------------------------|
| /dashboard            | ✅    | ✅     | 🚫     | middleware + getServerSession            |
| /api/internal/export  | ✅    | 🚫     | 🚫     | ❌ (no auth) → add matcher + assertPerm  |
| Server Action: publishPost | ✅ | ✅ | 🚫 | uses assertPermission("post:publish")    |

- Session: strategy="jwt", maxAge=30d, secure/httpOnly/sameSite=strict ✔
- CSRF: form actions use csrfToken from next-auth/react ✅
- Gap: /api/internal/export lacks auth; fix by extending middleware matcher

**Action**
1. Protect /api/internal/export via middleware + getServerSession
2. Add rate limiting to POST /api/forms (abuse risk)
```
