# Sentry Setup Guide for Next.js 14+ with @sentry/nextjs v8+

Next.js 14 + @sentry/nextjs v8+ 向けの包括的なSentryセットアップガイドです。

## ファイル構成

### 推奨構成（Next.js 14.x）

```
├── instrumentation.ts          # サーバー/Edge側の Sentry.init()
├── sentry.client.config.ts     # クライアント側の Sentry.init()
├── sentry.server.config.ts     # (v8+では instrumentation.ts 推奨)
├── sentry.edge.config.ts       # (v8+では instrumentation.ts 推奨)
└── next.config.js              # Sentryプラグイン設定
```

### 重要な違い

| ファイル           | Next.js 14.x              | Next.js 15.3+               |
| ------------------ | ------------------------- | --------------------------- |
| クライアント初期化 | `sentry.client.config.ts` | `instrumentation-client.ts` |
| サーバー初期化     | `instrumentation.ts`      | `instrumentation.ts`        |

## インストール

```bash
# pnpmの場合
pnpm add @sentry/nextjs

# npmの場合
npm install @sentry/nextjs

# セットアップウィザード（推奨）
npx @sentry/wizard@latest -i nextjs
```

## 環境変数設定

### 必須環境変数

```env
# .env.local
NEXT_PUBLIC_SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
SENTRY_AUTH_TOKEN=sntrys_xxx

# 環境識別（オプション）
SENTRY_ENVIRONMENT=development
```

### Vercel環境変数

Vercel Dashboardで以下を設定:

1. **NEXT_PUBLIC_SENTRY_DSN**: Production, Preview, Developmentすべてに設定
2. **SENTRY_AUTH_TOKEN**: Production, Previewに設定（ビルド時に必要）
3. **SENTRY_ORG**: Production, Previewに設定
4. **SENTRY_PROJECT**: Production, Previewに設定

## 設定ファイル

### next.config.js

```javascript
const { withSentryConfig } = require('@sentry/nextjs');

/** @type {import('next').NextConfig} */
const nextConfig = {
  // your existing config
};

module.exports = withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,

  // ソースマップアップロード設定
  silent: !process.env.CI,
  widenClientFileUpload: true,
  hideSourceMaps: true,
  disableLogger: true,

  // パフォーマンス最適化
  automaticVercelMonitors: true,
});
```

### instrumentation.ts

```typescript
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    await import('./sentry.server.config');
  }

  if (process.env.NEXT_RUNTIME === 'edge') {
    await import('./sentry.edge.config');
  }
}
```

### sentry.server.config.ts

```typescript
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.SENTRY_ENVIRONMENT || process.env.VERCEL_ENV || 'development',

  // パフォーマンスモニタリング
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

  // デバッグ（開発時のみ）
  debug: process.env.NODE_ENV === 'development',
});
```

### sentry.client.config.ts

```typescript
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.SENTRY_ENVIRONMENT || process.env.VERCEL_ENV || 'development',

  // パフォーマンスモニタリング
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

  // リプレイ
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  // インテグレーション
  integrations: [Sentry.replayIntegration()],

  // デバッグ（開発時のみ）
  debug: process.env.NODE_ENV === 'development',
});
```

### sentry.edge.config.ts

```typescript
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.SENTRY_ENVIRONMENT || process.env.VERCEL_ENV || 'development',
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
});
```

## CSP (Content Security Policy) 設定

### リージョン別Sentry Ingest URL

```
# US リージョン
connect-src *.ingest.us.sentry.io

# EU リージョン
connect-src *.ingest.de.sentry.io

# レガシー（非推奨）
connect-src *.ingest.sentry.io
```

### next.config.js での CSP 設定例

```javascript
const ContentSecurityPolicy = `
  default-src 'self';
  script-src 'self' 'unsafe-eval' 'unsafe-inline';
  connect-src 'self' *.ingest.us.sentry.io *.ingest.de.sentry.io;
`;

const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: ContentSecurityPolicy.replace(/\s{2,}/g, ' ').trim(),
  },
];
```

## Vercelカスタム環境対応

### staging環境など独自環境への対応

Vercel Integrationを使用している場合、カスタム環境（staging等）ではDSNが自動設定されません。

```javascript
// vercel.json または Vercel Dashboard
{
  "env": {
    "NEXT_PUBLIC_SENTRY_DSN": "@sentry-dsn"
  }
}
```

### Vercel API v9 での環境変数設定

```bash
# 環境変数を特定の環境に設定
curl -X POST "https://api.vercel.com/v9/projects/{projectId}/env" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "NEXT_PUBLIC_SENTRY_DSN",
    "value": "https://xxx@xxx.ingest.sentry.io/xxx",
    "target": ["preview"],
    "customEnvironmentIds": ["env_staging_xxx"]
  }'
```

## トラブルシューティング

### 1. DSNが設定されていない

**症状**: エラーがSentryに送信されない

**確認方法**:

```javascript
console.log('DSN:', process.env.NEXT_PUBLIC_SENTRY_DSN);
```

**解決策**:

- 環境変数が正しく設定されているか確認
- `NEXT_PUBLIC_` プレフィックスが付いているか確認
- Vercelの場合、デプロイ後に環境変数が反映されているか確認

### 2. CSPでブロックされている

**症状**: コンソールに `Refused to connect to 'https://xxx.ingest.sentry.io'` エラー

**解決策**:

- CSPの `connect-src` にリージョン別のURLを追加
- US: `*.ingest.us.sentry.io`
- EU: `*.ingest.de.sentry.io`

### 3. debug: true でもログが出ない

**症状**: `debug: true` を設定してもコンソールにSentryログが表示されない

**原因**: `disableLogger: true` が設定されている

**解決策**:

```javascript
// next.config.js
module.exports = withSentryConfig(nextConfig, {
  // 開発時はfalseに
  disableLogger: process.env.NODE_ENV === 'production',
});
```

### 4. Next.js 14でinstrumentation-client.tsが読み込まれない

**症状**: クライアント側のSentry初期化が実行されない

**原因**: `instrumentation-client.ts` はNext.js 15.3+でのみサポート

**解決策**:

- Next.js 14.xでは `sentry.client.config.ts` を使用
- next.config.jsで自動的に読み込まれる

### 5. ソースマップがアップロードされない

**症状**: Sentryのエラー詳細でソースコードが表示されない

**確認方法**:

```bash
# ビルドログを確認
npm run build 2>&1 | grep -i sentry
```

**解決策**:

- `SENTRY_AUTH_TOKEN` が設定されているか確認
- `SENTRY_ORG` と `SENTRY_PROJECT` が正しいか確認
- CI環境で `silent: !process.env.CI` を設定

## 動作確認

### クライアント側の確認

```typescript
// app/test-error/page.tsx
'use client';

export default function TestError() {
  return (
    <button
      onClick={() => {
        throw new Error('Test Sentry Error - Client');
      }}
    >
      Throw Client Error
    </button>
  );
}
```

### サーバー側の確認

```typescript
// app/api/test-error/route.ts
import * as Sentry from '@sentry/nextjs';

export async function GET() {
  try {
    throw new Error('Test Sentry Error - Server');
  } catch (error) {
    Sentry.captureException(error);
    return Response.json({ error: 'Test error sent to Sentry' });
  }
}
```

### SDK読み込み確認

```javascript
// ブラウザコンソールで実行
console.log('Sentry loaded:', typeof window.__SENTRY__ !== 'undefined');
console.log('Sentry hub:', window.__SENTRY__?.hub?.getClient()?.getDsn());
```

## ベストプラクティス

1. **環境ごとのサンプリングレート調整**
   - Production: 0.1 (10%)
   - Staging: 0.5 (50%)
   - Development: 1.0 (100%)

2. **機密情報のフィルタリング**

   ```typescript
   Sentry.init({
     beforeSend(event) {
       // パスワードなどの機密情報を除去
       if (event.request?.data) {
         delete event.request.data.password;
       }
       return event;
     },
   });
   ```

3. **リリースバージョンの設定**

   ```typescript
   Sentry.init({
     release: process.env.VERCEL_GIT_COMMIT_SHA || 'development',
   });
   ```

4. **ユーザーコンテキストの設定**
   ```typescript
   Sentry.setUser({
     id: user.id,
     email: user.email,
   });
   ```
