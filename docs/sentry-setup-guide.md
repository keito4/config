# Sentry Setup Guide for Next.js 14 with @sentry/nextjs v8+

このガイドは、Next.js 14 + @sentry/nextjs v8+ 環境での包括的なSentryセットアップ手順を提供します。

## 目次

- [ファイル構成と推奨構成](#ファイル構成と推奨構成)
- [環境変数設定](#環境変数設定)
- [Vercel環境でのセットアップ](#vercel環境でのセットアップ)
- [CSP（Content Security Policy）設定](#cspcontent-security-policy設定)
- [トラブルシューティング](#トラブルシューティング)

## ファイル構成と推奨構成

### Next.js 14.x での推奨構成

Next.js 14系では、以下のファイル構成を推奨します：

```
project-root/
├── instrumentation.ts              # サーバー/Edge側のSentry初期化（v8+推奨）
├── sentry.client.config.ts         # クライアント側のSentry初期化
├── sentry.server.config.ts         # サーバー側のSentry設定（オプション）
└── sentry.edge.config.ts           # Edge側のSentry設定（オプション）
```

### `instrumentation.ts` の実装

`instrumentation.ts` は Next.js 14+ でサーバー/Edge側の初期化を行うための推奨ファイルです：

```typescript
// instrumentation.ts
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    await import('./sentry.server.config');
  }

  if (process.env.NEXT_RUNTIME === 'edge') {
    await import('./sentry.edge.config');
  }
}
```

### `sentry.client.config.ts` vs `instrumentation-client.ts`

| ファイル名 | Next.js 14.x | Next.js 15.3+ | 推奨 |
|-----------|--------------|---------------|------|
| `sentry.client.config.ts` | ✅ 動作する | ✅ 動作する | Next.js 14では推奨 |
| `instrumentation-client.ts` | ❌ 読み込まれない | ✅ 動作する | Next.js 15.3+で推奨 |

**重要**: Next.js 14では `instrumentation-client.ts` が読み込まれないため、必ず `sentry.client.config.ts` を使用してください。

### `sentry.client.config.ts` の実装例

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NEXT_PUBLIC_APP_ENV || 'development',

  // パフォーマンスモニタリング
  tracesSampleRate: process.env.NEXT_PUBLIC_APP_ENV === 'production' ? 0.1 : 1.0,

  // セッションリプレイ
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  integrations: [
    Sentry.replayIntegration({
      maskAllText: true,
      blockAllMedia: true,
    }),
  ],

  // デバッグモード（開発環境のみ）
  debug: process.env.NODE_ENV === 'development',

  // 本番環境ではログを無効化（debug: trueとの相性問題を回避）
  disableLogger: process.env.NODE_ENV === 'production',
});
```

### `sentry.server.config.ts` の実装例

```typescript
// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NEXT_PUBLIC_APP_ENV || 'development',

  tracesSampleRate: process.env.NEXT_PUBLIC_APP_ENV === 'production' ? 0.1 : 1.0,

  debug: process.env.NODE_ENV === 'development',
  disableLogger: process.env.NODE_ENV === 'production',
});
```

## 環境変数設定

### 必須の環境変数

以下の環境変数を設定する必要があります：

```bash
# クライアント側で必要（NEXT_PUBLIC_ プレフィックス必須）
NEXT_PUBLIC_SENTRY_DSN=https://xxxxx@xxxxx.ingest.us.sentry.io/xxxxx

# ビルド時にソースマップアップロードで必要
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
SENTRY_AUTH_TOKEN=your-auth-token
```

### 環境識別の設定

Sentryで環境を識別するための設定方法：

#### 方法1: `SENTRY_ENVIRONMENT` を使用（推奨）

```bash
SENTRY_ENVIRONMENT=production
```

#### 方法2: カスタム環境変数を使用

```bash
NEXT_PUBLIC_APP_ENV=staging
```

**重要**: `SENTRY_ENVIRONMENT` が設定されている場合、それが優先されます。カスタム環境変数（`NEXT_PUBLIC_APP_ENV`）を使用する場合は、Sentry初期化時に明示的に指定してください。

### 環境変数の優先順位

1. `SENTRY_ENVIRONMENT` (最優先)
2. `NEXT_PUBLIC_APP_ENV`
3. `NODE_ENV` (フォールバック)

## Vercel環境でのセットアップ

### Vercel × Sentry Integration の設定

1. Vercelプロジェクト設定から「Integrations」を開く
2. 「Sentry」を検索してインストール
3. Sentryの組織とプロジェクトを選択
4. 自動的に以下の環境変数が設定されます：
   - `SENTRY_ORG`
   - `SENTRY_PROJECT`
   - `SENTRY_AUTH_TOKEN`
   - `NEXT_PUBLIC_SENTRY_DSN`

### カスタム環境（staging等）への対応

Vercelのカスタム環境（Preview以外のブランチ環境）でSentryを有効にするには、`vercel.json` で明示的に指定する必要があります：

```json
{
  "build": {
    "env": {
      "SENTRY_ORG": "@sentry-org",
      "SENTRY_PROJECT": "@sentry-project",
      "SENTRY_AUTH_TOKEN": "@sentry-auth-token"
    }
  },
  "env": {
    "NEXT_PUBLIC_SENTRY_DSN": "@next-public-sentry-dsn"
  }
}
```

または、Vercel Integration設定で `customEnvironmentIds` を指定：

```javascript
// next.config.js
const { withSentryConfig } = require('@sentry/nextjs');

module.exports = withSentryConfig(
  {
    // Next.js設定
  },
  {
    // Sentry設定
    silent: true,
    org: process.env.SENTRY_ORG,
    project: process.env.SENTRY_PROJECT,

    // カスタム環境IDを指定
    deploy: {
      env: {
        customEnvironmentIds: ['staging', 'uat'],
      },
    },
  }
);
```

### Vercel API v9 での環境変数更新

Vercel API を使用して環境変数を更新する場合：

```bash
# 環境変数の追加/更新
curl -X POST "https://api.vercel.com/v9/projects/${PROJECT_ID}/env" \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "key": "NEXT_PUBLIC_SENTRY_DSN",
    "value": "https://xxxxx@xxxxx.ingest.us.sentry.io/xxxxx",
    "type": "plain",
    "target": ["production", "preview"]
  }'
```

## CSP（Content Security Policy）設定

### リージョン別Sentry Ingest URL

Sentryのデータ送信先はリージョンによって異なります。CSPで正しいURLを許可する必要があります：

| リージョン | Ingest URL | 使用例 |
|-----------|------------|--------|
| US | `*.ingest.us.sentry.io` | デフォルト（米国） |
| EU | `*.ingest.de.sentry.io` | GDPR対応が必要な場合 |

### CSP設定例（US リージョン）

```typescript
// next.config.js
const ContentSecurityPolicy = `
  default-src 'self';
  script-src 'self' 'unsafe-eval' 'unsafe-inline';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self' data:;
  connect-src 'self' *.ingest.us.sentry.io;
  frame-src 'self';
`;

const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: ContentSecurityPolicy.replace(/\s{2,}/g, ' ').trim(),
  },
];

module.exports = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
};
```

### よくある間違い

❌ **誤り**: `*.ingest.sentry.io` のみを設定
```
connect-src 'self' *.ingest.sentry.io;
```

✅ **正しい**: リージョン別URLを指定
```
connect-src 'self' *.ingest.us.sentry.io;  # US
connect-src 'self' *.ingest.de.sentry.io;  # EU
```

## トラブルシューティング

### 問題1: DSNが設定されていない

#### 症状
- ブラウザのコンソールに何も表示されない
- Sentryにイベントが送信されない

#### 確認方法
```javascript
// ブラウザのコンソールで確認
console.log(process.env.NEXT_PUBLIC_SENTRY_DSN);
```

#### 解決策
1. `.env.local` に `NEXT_PUBLIC_SENTRY_DSN` が設定されているか確認
2. 環境変数は `NEXT_PUBLIC_` プレフィックスが必須（クライアント側で使用する場合）
3. 開発サーバーを再起動

### 問題2: CSPブロック vs アドブロッカー

#### 症状
- ブラウザのコンソールに「blocked by CSP」エラー
- Sentryへのリクエストが失敗

#### 識別方法

**CSPブロックの場合**:
```
Refused to connect to 'https://xxxxx.ingest.us.sentry.io/api/xxxxx/envelope/'
because it violates the following Content Security Policy directive: "connect-src 'self'"
```

**アドブロッカーの場合**:
```
net::ERR_BLOCKED_BY_CLIENT
```

#### 解決策

**CSPブロックの場合**:
- `connect-src` ディレクティブに Sentry Ingest URL を追加（上記 [CSP設定](#cspcontent-security-policy設定) を参照）

**アドブロッカーの場合**:
- アドブロッカーを一時的に無効化してテスト
- 本番環境では問題ないことを確認

### 問題3: `debug: true` でもログが出ない

#### 症状
- `debug: true` を設定してもコンソールにログが出力されない

#### 原因
`disableLogger: true` と `debug: true` は相性が悪く、`disableLogger: true` が優先されます。

#### 解決策
デバッグ時は `disableLogger` を `false` に設定：

```typescript
Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  debug: true,
  disableLogger: false,  // デバッグ時は false に設定
});
```

### 問題4: クライアント/サーバーSDKが読み込まれない

#### 確認方法

**クライアント側**:
```javascript
// ブラウザのコンソールで確認
if (window.Sentry) {
  console.log('Sentry client SDK loaded');
} else {
  console.error('Sentry client SDK not loaded');
}
```

**サーバー側**:
```javascript
// API RouteやServer Componentで確認
import * as Sentry from '@sentry/nextjs';

export async function GET() {
  console.log('Sentry server SDK:', !!Sentry);
  return new Response('OK');
}
```

#### 解決策

1. **ファイル配置を確認**:
   - Next.js 14: `sentry.client.config.ts` を使用
   - Next.js 15.3+: `instrumentation-client.ts` を使用

2. **Next.js設定を確認**:
```javascript
// next.config.js
const { withSentryConfig } = require('@sentry/nextjs');

module.exports = withSentryConfig(
  {
    // Next.js設定
  },
  {
    // Sentry設定
    silent: true,
    widenClientFileUpload: true,
    hideSourceMaps: true,
  }
);
```

3. **ビルドキャッシュをクリア**:
```bash
rm -rf .next
npm run build
```

### 問題5: Next.js 14で `instrumentation-client.ts` が読み込まれない

#### 症状
- `instrumentation-client.ts` を作成してもクライアント側でSentryが初期化されない

#### 原因
Next.js 14.x では `instrumentation-client.ts` がサポートされていません（Next.js 15.3+ から対応）。

#### 解決策
Next.js 14では `sentry.client.config.ts` を使用してください：

```typescript
// sentry.client.config.ts（Next.js 14で使用）
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  // ...
});
```

### 問題6: Vercelカスタム環境でDSNが設定されない

#### 症状
- Production/Preview環境では動作するが、staging等のカスタム環境では動作しない

#### 原因
Vercel Integration は Production と Preview 環境のみを自動設定します。

#### 解決策
`vercel.json` で明示的に環境変数を設定（上記 [カスタム環境への対応](#カスタム環境staging等への対応) を参照）。

## まとめ

このガイドで解決する主な問題：

| 問題 | 解決策 |
|------|--------|
| Next.js 14で `instrumentation-client.ts` が読み込まれない | `sentry.client.config.ts` を使用 |
| Vercelカスタム環境でDSNが設定されない | `customEnvironmentIds` で明示的に指定 |
| CSPで `*.ingest.sentry.io` のみ設定 | リージョン別URL（`*.ingest.us.sentry.io`等）を追加 |
| `debug: true` でもログが出ない | `disableLogger: true` との相性問題を確認 |

## 参考リソース

- [Sentry Next.js Documentation](https://docs.sentry.io/platforms/javascript/guides/nextjs/)
- [Next.js Instrumentation](https://nextjs.org/docs/app/building-your-application/optimizing/instrumentation)
- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)
- [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

---

🤖 このガイドは本番運用での実績に基づいて作成されました
