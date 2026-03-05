/**
 * Performance Test Example
 *
 * パフォーマンステストは、Core Web Vitalsや
 * ページロード時間を測定するテストです。
 *
 * tests/performance/lighthouse.spec.ts として配置してください。
 *
 * 依存パッケージ:
 * npm install -D @playwright/test lighthouse
 *
 * CI設定例: .github/workflows/lighthouse.yml
 */

import { test, expect } from '@playwright/test';

// Lighthouse の型定義
interface LighthouseResult {
  lhr: {
    categories: {
      performance: { score: number };
      accessibility: { score: number };
      'best-practices': { score: number };
      seo: { score: number };
    };
    audits: {
      'first-contentful-paint': { numericValue: number };
      'largest-contentful-paint': { numericValue: number };
      'cumulative-layout-shift': { numericValue: number };
      'total-blocking-time': { numericValue: number };
      'speed-index': { numericValue: number };
      interactive: { numericValue: number };
    };
  };
}

// Core Web Vitals のしきい値
const THRESHOLDS = {
  // Lighthouse スコア（0-1）
  performance: 0.9,
  accessibility: 0.9,
  bestPractices: 0.9,
  seo: 0.9,

  // Core Web Vitals（ミリ秒）
  lcp: 2500, // Largest Contentful Paint
  fcp: 1800, // First Contentful Paint
  cls: 0.1, // Cumulative Layout Shift
  tbt: 200, // Total Blocking Time
  tti: 3800, // Time to Interactive
};

test.describe('Performance Tests', () => {
  test.describe('Core Web Vitals', () => {
    test('ホームページのパフォーマンス', async ({ page }) => {
      await page.goto('/');

      // Performance API を使用してメトリクスを取得
      const metrics = await page.evaluate(() => {
        return new Promise((resolve) => {
          // ページ読み込み完了を待機
          if (document.readyState === 'complete') {
            collectMetrics();
          } else {
            window.addEventListener('load', collectMetrics);
          }

          function collectMetrics() {
            const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
            const paint = performance.getEntriesByType('paint');

            const fcp = paint.find((entry) => entry.name === 'first-contentful-paint');

            resolve({
              // Navigation Timing
              domContentLoaded: navigation.domContentLoadedEventEnd - navigation.startTime,
              load: navigation.loadEventEnd - navigation.startTime,
              ttfb: navigation.responseStart - navigation.requestStart,

              // Paint Timing
              fcp: fcp ? fcp.startTime : null,

              // DOM サイズ
              domElements: document.querySelectorAll('*').length,
            });
          }
        });
      });

      console.log('Performance Metrics:', metrics);

      // アサーション
      expect((metrics as Record<string, number>).fcp).toBeLessThan(THRESHOLDS.fcp);
      expect((metrics as Record<string, number>).load).toBeLessThan(5000);
    });

    test('ダッシュボードのパフォーマンス', async ({ page }) => {
      // ログイン
      await page.goto('/login');
      await page.getByLabel(/メールアドレス/i).fill(process.env.TEST_USER_EMAIL || 'test@example.com');
      await page.getByLabel(/パスワード/i).fill(process.env.TEST_USER_PASSWORD || 'password');
      await page.getByRole('button', { name: /ログイン/i }).click();

      await page.waitForURL(/\/dashboard/);

      // メトリクス収集
      const metrics = await page.evaluate(() => {
        const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;

        return {
          load: navigation.loadEventEnd - navigation.startTime,
          domElements: document.querySelectorAll('*').length,
        };
      });

      console.log('Dashboard Metrics:', metrics);

      // ダッシュボードは重いページなので緩めのしきい値
      expect(metrics.load).toBeLessThan(8000);
      expect(metrics.domElements).toBeLessThan(5000);
    });
  });

  test.describe('リソース最適化', () => {
    test('JavaScript バンドルサイズ', async ({ page }) => {
      const jsRequests: { url: string; size: number }[] = [];

      page.on('response', async (response) => {
        const url = response.url();
        if (url.endsWith('.js') || url.includes('/_next/static/')) {
          const headers = response.headers();
          const size = parseInt(headers['content-length'] || '0', 10);
          jsRequests.push({ url, size });
        }
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      const totalJsSize = jsRequests.reduce((sum, req) => sum + req.size, 0);
      console.log(`Total JS size: ${(totalJsSize / 1024).toFixed(2)} KB`);

      // 1MB以下であることを確認
      expect(totalJsSize).toBeLessThan(1024 * 1024);
    });

    test('画像の最適化', async ({ page }) => {
      const imageRequests: { url: string; size: number; type: string }[] = [];

      page.on('response', async (response) => {
        const contentType = response.headers()['content-type'] || '';
        if (contentType.startsWith('image/')) {
          const size = parseInt(response.headers()['content-length'] || '0', 10);
          imageRequests.push({
            url: response.url(),
            size,
            type: contentType,
          });
        }
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // 各画像が 500KB 以下
      for (const img of imageRequests) {
        expect(img.size).toBeLessThan(500 * 1024);
      }

      // WebP または AVIF が使用されていることを確認（オプション）
      const modernFormats = imageRequests.filter((img) => img.type.includes('webp') || img.type.includes('avif'));

      console.log(`Modern format images: ${modernFormats.length}/${imageRequests.length}`);
    });

    test('Third-party スクリプトの数', async ({ page }) => {
      const thirdPartyScripts: string[] = [];
      const ownDomain = new URL(process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000').hostname;

      page.on('request', (request) => {
        const url = new URL(request.url());
        if (request.resourceType() === 'script' && url.hostname !== ownDomain) {
          thirdPartyScripts.push(url.hostname);
        }
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      console.log('Third-party scripts:', [...new Set(thirdPartyScripts)]);

      // サードパーティスクリプトは5個以下
      expect(new Set(thirdPartyScripts).size).toBeLessThan(5);
    });
  });

  test.describe('インタラクション', () => {
    test('ボタンクリックの応答時間', async ({ page }) => {
      await page.goto('/');

      const button = page.getByRole('button').first();

      if (await button.isVisible()) {
        const startTime = Date.now();

        await button.click();

        // 何らかのレスポンスを待機（例: ナビゲーション、モーダル表示）
        await page.waitForTimeout(100);

        const responseTime = Date.now() - startTime;
        console.log(`Button response time: ${responseTime}ms`);

        // 100ms以下
        expect(responseTime).toBeLessThan(100);
      }
    });

    test('フォーム入力の遅延がない', async ({ page }) => {
      await page.goto('/login');

      const input = page.getByLabel(/メールアドレス/i);

      const startTime = Date.now();

      await input.fill('test@example.com');

      const fillTime = Date.now() - startTime;
      console.log(`Input fill time: ${fillTime}ms`);

      // 入力に 50ms 以上かからない
      expect(fillTime).toBeLessThan(50);
    });
  });

  test.describe('メモリリーク検出', () => {
    test('ページ遷移でメモリが増加し続けない', async ({ page }) => {
      await page.goto('/');

      // 初期メモリ使用量を取得
      const getMemory = async () => {
        return page.evaluate(() => {
          // @ts-expect-error - performance.memory は Chrome のみ
          return performance.memory?.usedJSHeapSize || 0;
        });
      };

      const initialMemory = await getMemory();

      // 複数回ページ遷移
      for (let i = 0; i < 5; i++) {
        await page.goto('/about');
        await page.goto('/');
      }

      const finalMemory = await getMemory();

      if (initialMemory > 0 && finalMemory > 0) {
        const memoryIncrease = finalMemory - initialMemory;
        console.log(`Memory increase: ${(memoryIncrease / 1024 / 1024).toFixed(2)} MB`);

        // メモリ増加が 50MB 以下
        expect(memoryIncrease).toBeLessThan(50 * 1024 * 1024);
      }
    });
  });
});
