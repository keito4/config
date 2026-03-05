/**
 * Visual Regression Test Example
 *
 * ビジュアルリグレッションテストは、UIの見た目が
 * 意図せず変更されていないことを確認するテストです。
 *
 * tests/visual/pages.spec.ts として配置してください。
 *
 * 注意: 初回実行時はベースラインスナップショットが作成されます。
 * npx playwright test --update-snapshots でスナップショットを更新できます。
 */

import { test, expect } from '@playwright/test';

test.describe('ビジュアルリグレッションテスト', () => {
  test.describe('認証ページ', () => {
    test('ログインページのレイアウト', async ({ page }) => {
      await page.goto('/login');

      // ページの読み込み完了を待機
      await page.waitForLoadState('networkidle');

      // スクリーンショットを撮影してベースラインと比較
      await expect(page).toHaveScreenshot('login-page.png', {
        maxDiffPixelRatio: 0.01, // 1%の差異まで許容
        fullPage: true,
      });
    });

    test('新規登録ページのレイアウト', async ({ page }) => {
      await page.goto('/signup');
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveScreenshot('signup-page.png', {
        maxDiffPixelRatio: 0.01,
        fullPage: true,
      });
    });
  });

  test.describe('ダッシュボード', () => {
    test.beforeEach(async ({ page }) => {
      // ログイン状態をセットアップ
      await page.goto('/login');
      await page.getByLabel(/メールアドレス/i).fill(process.env.TEST_USER_EMAIL || 'test@example.com');
      await page.getByLabel(/パスワード/i).fill(process.env.TEST_USER_PASSWORD || 'password');
      await page.getByRole('button', { name: /ログイン/i }).click();
      await page.waitForURL(/\/dashboard/);
    });

    test('ダッシュボードのレイアウト', async ({ page }) => {
      await page.waitForLoadState('networkidle');

      // 動的コンテンツをマスク
      await expect(page).toHaveScreenshot('dashboard.png', {
        maxDiffPixelRatio: 0.02,
        fullPage: true,
        mask: [page.locator('[data-testid="current-time"]'), page.locator('[data-testid="user-avatar"]')],
      });
    });

    test('サイドバーナビゲーション', async ({ page }) => {
      const sidebar = page.locator('[data-testid="sidebar"]');

      await expect(sidebar).toHaveScreenshot('sidebar.png', {
        maxDiffPixelRatio: 0.01,
      });
    });
  });

  test.describe('レスポンシブデザイン', () => {
    test('モバイルビューでのログインページ', async ({ page }) => {
      // モバイルビューポートを設定
      await page.setViewportSize({ width: 375, height: 667 });
      await page.goto('/login');
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveScreenshot('login-mobile.png', {
        maxDiffPixelRatio: 0.01,
        fullPage: true,
      });
    });

    test('タブレットビューでのダッシュボード', async ({ page }) => {
      await page.setViewportSize({ width: 768, height: 1024 });

      // ログイン
      await page.goto('/login');
      await page.getByLabel(/メールアドレス/i).fill(process.env.TEST_USER_EMAIL || 'test@example.com');
      await page.getByLabel(/パスワード/i).fill(process.env.TEST_USER_PASSWORD || 'password');
      await page.getByRole('button', { name: /ログイン/i }).click();
      await page.waitForURL(/\/dashboard/);
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveScreenshot('dashboard-tablet.png', {
        maxDiffPixelRatio: 0.02,
        fullPage: true,
      });
    });
  });

  test.describe('ダークモード', () => {
    test('ダークモードでのログインページ', async ({ page }) => {
      // ダークモードを有効化
      await page.emulateMedia({ colorScheme: 'dark' });
      await page.goto('/login');
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveScreenshot('login-dark.png', {
        maxDiffPixelRatio: 0.01,
        fullPage: true,
      });
    });
  });

  test.describe('コンポーネント単体', () => {
    test('ボタンの各バリアント', async ({ page }) => {
      // Storybookまたはコンポーネントプレビューページ
      await page.goto('/components/button-preview');
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveScreenshot('buttons.png', {
        maxDiffPixelRatio: 0.01,
      });
    });

    test('フォーム要素', async ({ page }) => {
      await page.goto('/components/form-preview');
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveScreenshot('form-elements.png', {
        maxDiffPixelRatio: 0.01,
      });
    });
  });
});
