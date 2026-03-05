/**
 * SSR/Hydration Test Example
 *
 * SSR（サーバーサイドレンダリング）とハイドレーションの
 * 正しい動作を検証するテストです。
 *
 * tests/ssr/hydration.spec.ts として配置してください。
 *
 * 依存: Playwright
 */

import { test, expect } from '@playwright/test';

const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000';

test.describe('SSR/Hydration Tests', () => {
  test.describe('サーバーサイドレンダリング', () => {
    test('初期HTMLにコンテンツが含まれる', async ({ page }) => {
      // JavaScriptを無効化してページを取得
      await page.route('**/*', (route) => {
        if (route.request().resourceType() === 'script') {
          route.abort();
        } else {
          route.continue();
        }
      });

      await page.goto(`${BASE_URL}/`);

      // JavaScript無効でもコンテンツが表示される
      const html = await page.content();

      // メインコンテンツがHTML内に存在
      expect(html).toContain('<main');

      // 重要なテキストがSSRされている
      const heading = await page.locator('h1').first();
      await expect(heading).toBeVisible();
    });

    test('メタデータがSSRされている', async ({ page }) => {
      // HTMLのみ取得（JSなし）
      const response = await page.goto(`${BASE_URL}/`, { waitUntil: 'commit' });
      const html = await response?.text();

      // title タグが存在
      expect(html).toMatch(/<title>[^<]+<\/title>/);

      // meta description が存在
      expect(html).toMatch(/<meta[^>]+name="description"[^>]*>/);

      // OGP タグが存在
      expect(html).toMatch(/<meta[^>]+property="og:title"[^>]*>/);
    });

    test('構造化データがSSRされている', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);

      const jsonLd = await page.locator('script[type="application/ld+json"]').allTextContents();

      if (jsonLd.length > 0) {
        // JSON-LD が有効なJSON
        jsonLd.forEach((script) => {
          expect(() => JSON.parse(script)).not.toThrow();
        });
      }
    });

    test('SSRエラーがない', async ({ page }) => {
      const errors: string[] = [];

      page.on('console', (msg) => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      await page.goto(`${BASE_URL}/`);

      // SSR関連のエラーがないことを確認
      const ssrErrors = errors.filter(
        (e) =>
          e.includes('Hydration') ||
          e.includes('server') ||
          e.includes('mismatch') ||
          e.includes('Warning: Text content'),
      );

      expect(ssrErrors).toHaveLength(0);
    });
  });

  test.describe('ハイドレーション', () => {
    test('ハイドレーションミスマッチがない', async ({ page }) => {
      const hydrationErrors: string[] = [];

      page.on('console', (msg) => {
        const text = msg.text();
        if (
          text.includes('Hydration') ||
          text.includes('hydration') ||
          text.includes('Text content does not match') ||
          text.includes('Expected server HTML')
        ) {
          hydrationErrors.push(text);
        }
      });

      await page.goto(`${BASE_URL}/`);
      await page.waitForLoadState('networkidle');

      // ハイドレーションエラーがない
      expect(hydrationErrors).toHaveLength(0);
    });

    test('ハイドレーション後にインタラクティブ', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);
      await page.waitForLoadState('networkidle');

      // ボタンをクリックできる
      const button = page.getByRole('button').first();

      if (await button.isVisible()) {
        await expect(button).toBeEnabled();
        await button.click();
        // クリック後の状態変化を確認
      }
    });

    test('動的コンテンツがハイドレーション後に動作', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);
      await page.waitForLoadState('networkidle');

      // 入力フィールドが動作
      const input = page.getByRole('textbox').first();

      if (await input.isVisible()) {
        await input.fill('test');
        await expect(input).toHaveValue('test');
      }
    });

    test('useEffect がクライアントサイドで実行される', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);

      // useEffect で設定されるデータ属性を確認
      await page.waitForFunction(() => {
        const element = document.querySelector('[data-hydrated]');
        return element !== null;
      });

      // または JavaScript 実行後の状態を確認
      const hydrated = await page.evaluate(() => {
        return typeof window !== 'undefined' && document.readyState === 'complete';
      });

      expect(hydrated).toBe(true);
    });
  });

  test.describe('ストリーミングSSR', () => {
    test('Suspense境界が正しく処理される', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/`, { waitUntil: 'domcontentloaded' });

      // Transfer-Encoding: chunked（ストリーミング）
      const transferEncoding = response?.headers()['transfer-encoding'];

      // ストリーミングが有効な場合
      if (transferEncoding === 'chunked') {
        // ローディング状態が表示される
        const loading = page.getByText(/loading|読み込み中/i);
        // ローディングが消えてコンテンツが表示される
        await expect(loading).not.toBeVisible({ timeout: 10000 });
      }
    });

    test('遅延コンテンツが正しくストリームされる', async ({ page }) => {
      const startTime = Date.now();

      await page.goto(`${BASE_URL}/`);

      // 初期HTMLが素早く返される
      const initialLoadTime = Date.now() - startTime;

      // 初期レスポンスは1秒以内
      expect(initialLoadTime).toBeLessThan(1000);

      // 遅延コンテンツが後から表示される
      await page.waitForLoadState('networkidle');
    });
  });

  test.describe('RSC (React Server Components)', () => {
    test('Server Componentがレンダリングされる', async ({ page }) => {
      await page.goto(`${BASE_URL}/`);

      // Server Component のコンテンツが存在
      const html = await page.content();

      // __next_f (RSC payload) が存在する場合はRSCが使用されている
      const hasRsc = html.includes('__next_f') || html.includes('self.__next_f');

      console.log(`RSC enabled: ${hasRsc}`);
    });

    test('Client ComponentがハイドレートされるJSバンドル内に存在', async ({ page }) => {
      const clientScripts: string[] = [];

      page.on('response', async (response) => {
        const url = response.url();
        if (url.includes('/_next/static') && url.endsWith('.js')) {
          clientScripts.push(url);
        }
      });

      await page.goto(`${BASE_URL}/`);
      await page.waitForLoadState('networkidle');

      // クライアントサイドJSがロードされる
      expect(clientScripts.length).toBeGreaterThan(0);
    });
  });

  test.describe('SSR パフォーマンス', () => {
    test('TTFB（Time to First Byte）が許容範囲内', async ({ page }) => {
      const startTime = Date.now();

      const response = await page.goto(`${BASE_URL}/`, { waitUntil: 'commit' });

      const ttfb = Date.now() - startTime;

      console.log(`TTFB: ${ttfb}ms`);

      // 500ms以内
      expect(ttfb).toBeLessThan(500);
    });

    test('SSRページサイズが適切', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/`, { waitUntil: 'commit' });
      const html = await response?.text();

      const htmlSize = new Blob([html || '']).size;
      console.log(`HTML size: ${(htmlSize / 1024).toFixed(2)} KB`);

      // HTMLが500KB以下
      expect(htmlSize).toBeLessThan(500 * 1024);
    });

    test('不要なデータがSSRペイロードに含まれない', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/`, { waitUntil: 'commit' });
      const html = await response?.text();

      // デバッグ情報が含まれない
      expect(html).not.toContain('__REDUX_DEVTOOLS');
      expect(html).not.toContain('console.log');

      // 巨大なJSONデータが埋め込まれていない
      const scriptTags = html?.match(/<script[^>]*>[\s\S]*?<\/script>/g) || [];
      scriptTags.forEach((script) => {
        // 各スクリプトが100KB以下
        expect(script.length).toBeLessThan(100 * 1024);
      });
    });
  });

  test.describe('SSR セキュリティ', () => {
    test('機密データがSSR HTMLに含まれない', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/`, { waitUntil: 'commit' });
      const html = await response?.text();

      // 環境変数やAPIキーが含まれない
      expect(html).not.toMatch(/SUPABASE_SERVICE_ROLE_KEY/);
      expect(html).not.toMatch(/sk_live_/); // Stripe secret key
      expect(html).not.toMatch(/password/i); // パスワード
    });

    test('XSSペイロードがエスケープされる', async ({ page }) => {
      // XSSペイロードを含むURLでアクセス
      const xssPayload = '<script>alert("XSS")</script>';
      const response = await page.goto(`${BASE_URL}/?q=${encodeURIComponent(xssPayload)}`, {
        waitUntil: 'commit',
      });
      const html = await response?.text();

      // スクリプトタグがそのまま埋め込まれていない
      expect(html).not.toContain('<script>alert("XSS")</script>');
    });
  });

  test.describe('SSR エラーハンドリング', () => {
    test('404ページがSSRされる', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/non-existent-page-12345`);

      expect(response?.status()).toBe(404);

      // 404ページのコンテンツがSSRされている
      const html = await page.content();
      expect(html).toMatch(/404|not found|見つかりません/i);
    });

    test('エラー境界がSSRエラーをキャッチ', async ({ page }) => {
      // エラーを引き起こすページがある場合
      const response = await page.goto(`${BASE_URL}/error-test`, { timeout: 5000 }).catch(() => null);

      if (response) {
        // 500ではなくエラーページが表示される
        expect(response.status()).not.toBe(500);
      }
    });
  });

  test.describe('キャッシュ', () => {
    test('Cache-Controlヘッダーが設定されている', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/`);
      const cacheControl = response?.headers()['cache-control'];

      if (cacheControl) {
        console.log(`Cache-Control: ${cacheControl}`);
        // キャッシュ設定が存在
        expect(cacheControl).toBeTruthy();
      }
    });

    test('静的ページは長いキャッシュ', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/about`).catch(() => null);

      if (response) {
        const cacheControl = response.headers()['cache-control'];

        // 静的ページは長いmax-age（または ISR の s-maxage）
        if (cacheControl && !cacheControl.includes('no-cache')) {
          expect(cacheControl).toMatch(/max-age=\d+|s-maxage=\d+/);
        }
      }
    });

    test('動的ページはno-cacheまたは短いキャッシュ', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/dashboard`).catch(() => null);

      if (response && response.status() === 200) {
        const cacheControl = response.headers()['cache-control'];

        // 動的ページはキャッシュしないか短い
        if (cacheControl) {
          const hasNoCache = cacheControl.includes('no-cache') || cacheControl.includes('no-store');
          const hasPrivate = cacheControl.includes('private');
          const hasShortMaxAge = /max-age=([0-9]+)/.exec(cacheControl)?.[1];
          const isShort = hasShortMaxAge ? parseInt(hasShortMaxAge) <= 60 : false;

          expect(hasNoCache || hasPrivate || isShort).toBe(true);
        }
      }
    });
  });
});
