/**
 * Auth Regression Test Example
 *
 * 認証機能のリグレッションテストです。
 * 過去に発生したバグが再発していないことを確認します。
 *
 * tests/regression/auth-regression.spec.ts として配置してください。
 */

import { test, expect } from '@playwright/test';

test.describe('認証リグレッションテスト', () => {
  test.beforeEach(async ({ page }) => {
    // 各テスト前にセッションをクリア
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });
  });

  test.describe('REG-001: ログイン後のリダイレクト', () => {
    test('ログイン後、元のページにリダイレクトされる', async ({ page }) => {
      // 保護されたページにアクセス
      await page.goto('/dashboard/settings');

      // ログインページにリダイレクトされる
      await expect(page).toHaveURL(/\/login/);

      // redirect パラメータが含まれている
      const url = new URL(page.url());
      expect(url.searchParams.get('redirect')).toBe('/dashboard/settings');

      // ログイン
      await page.getByLabel(/メールアドレス/i).fill(process.env.TEST_USER_EMAIL || 'test@example.com');
      await page.getByLabel(/パスワード/i).fill(process.env.TEST_USER_PASSWORD || 'password');
      await page.getByRole('button', { name: /ログイン/i }).click();

      // 元のページにリダイレクト
      await expect(page).toHaveURL(/\/dashboard\/settings/);
    });
  });

  test.describe('REG-002: セッション切れの処理', () => {
    test('セッション切れ時にログインページにリダイレクトされる', async ({ page }) => {
      // ログイン状態をシミュレート（実際のテストでは認証済みセッションを使用）
      await page.goto('/dashboard');

      // セッションを無効化
      await page.evaluate(() => {
        localStorage.removeItem('supabase.auth.token');
      });

      // APIリクエストを発生させる操作
      await page.reload();

      // ログインページにリダイレクト
      await expect(page).toHaveURL(/\/login/);
    });
  });

  test.describe('REG-003: RBAC境界値テスト', () => {
    test('一般ユーザーは管理者ページにアクセスできない', async ({ page }) => {
      // 一般ユーザーとしてログイン
      await page.goto('/login');
      await page.getByLabel(/メールアドレス/i).fill(process.env.TEST_REGULAR_USER_EMAIL || 'user@example.com');
      await page.getByLabel(/パスワード/i).fill(process.env.TEST_REGULAR_USER_PASSWORD || 'password');
      await page.getByRole('button', { name: /ログイン/i }).click();

      // 管理者ページにアクセス試行
      await page.goto('/admin');

      // 403 または リダイレクト
      const url = page.url();
      const is403 = await page
        .getByText(/アクセス権限がありません/i)
        .isVisible()
        .catch(() => false);
      const isRedirected = !url.includes('/admin');

      expect(is403 || isRedirected).toBe(true);
    });
  });

  test.describe('REG-004: パスワードリセットフロー', () => {
    test('パスワードリセットメールが送信される', async ({ page }) => {
      await page.goto('/login');

      // パスワードを忘れた場合のリンク
      await page.getByRole('link', { name: /パスワードを忘れた/i }).click();

      await expect(page).toHaveURL(/\/forgot-password/);

      // メールアドレスを入力
      await page.getByLabel(/メールアドレス/i).fill('test@example.com');
      await page.getByRole('button', { name: /送信/i }).click();

      // 成功メッセージ
      await expect(page.getByText(/メールを送信しました/i)).toBeVisible();
    });
  });

  test.describe('REG-005: XSS防止', () => {
    test('ログインフォームでXSSが実行されない', async ({ page }) => {
      await page.goto('/login');

      const xssPayload = '<script>alert("XSS")</script>';

      await page.getByLabel(/メールアドレス/i).fill(xssPayload);
      await page.getByLabel(/パスワード/i).fill(xssPayload);
      await page.getByRole('button', { name: /ログイン/i }).click();

      // アラートが表示されないことを確認
      let alertShown = false;
      page.on('dialog', () => {
        alertShown = true;
      });

      await page.waitForTimeout(1000);
      expect(alertShown).toBe(false);
    });
  });

  test.describe('REG-006: CSRF保護', () => {
    test('CSRFトークンなしのPOSTリクエストは拒否される', async ({ page }) => {
      await page.goto('/login');

      // 直接POSTリクエストを送信（CSRFトークンなし）
      const response = await page.request.post('/api/auth/login', {
        data: {
          email: 'test@example.com',
          password: 'password',
        },
        headers: {
          'Content-Type': 'application/json',
        },
      });

      // 403 または 401（CSRF検証失敗）
      expect([401, 403]).toContain(response.status());
    });
  });
});
