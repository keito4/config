/**
 * E2E Auth Test Example
 *
 * このファイルは Playwright による認証フローのE2Eテスト例です。
 * tests/e2e/auth.spec.ts として配置してください。
 */

import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test.beforeEach(async ({ page }) => {
    // テスト前にログアウト状態にする
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });
  });

  test('should display login page', async ({ page }) => {
    await page.goto('/login');

    await expect(page.getByRole('heading', { name: /ログイン/i })).toBeVisible();
    await expect(page.getByLabel(/メールアドレス/i)).toBeVisible();
    await expect(page.getByLabel(/パスワード/i)).toBeVisible();
    await expect(page.getByRole('button', { name: /ログイン/i })).toBeVisible();
  });

  test('should show validation errors for empty form', async ({ page }) => {
    await page.goto('/login');

    await page.getByRole('button', { name: /ログイン/i }).click();

    await expect(page.getByText(/メールアドレスを入力してください/i)).toBeVisible();
    await expect(page.getByText(/パスワードを入力してください/i)).toBeVisible();
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.getByLabel(/メールアドレス/i).fill('invalid@example.com');
    await page.getByLabel(/パスワード/i).fill('wrongpassword');
    await page.getByRole('button', { name: /ログイン/i }).click();

    await expect(page.getByText(/メールアドレスまたはパスワードが正しくありません/i)).toBeVisible();
  });

  test('should redirect to dashboard after successful login', async ({ page }) => {
    await page.goto('/login');

    // テスト用の認証情報を使用
    await page.getByLabel(/メールアドレス/i).fill(process.env.TEST_USER_EMAIL || 'test@example.com');
    await page.getByLabel(/パスワード/i).fill(process.env.TEST_USER_PASSWORD || 'testpassword');
    await page.getByRole('button', { name: /ログイン/i }).click();

    // ダッシュボードへのリダイレクトを確認
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.getByRole('heading', { name: /ダッシュボード/i })).toBeVisible();
  });

  test('should logout successfully', async ({ page }) => {
    // まずログイン
    await page.goto('/login');
    await page.getByLabel(/メールアドレス/i).fill(process.env.TEST_USER_EMAIL || 'test@example.com');
    await page.getByLabel(/パスワード/i).fill(process.env.TEST_USER_PASSWORD || 'testpassword');
    await page.getByRole('button', { name: /ログイン/i }).click();

    await expect(page).toHaveURL(/\/dashboard/);

    // ログアウト
    await page.getByRole('button', { name: /ユーザーメニュー/i }).click();
    await page.getByRole('menuitem', { name: /ログアウト/i }).click();

    // ログインページへリダイレクト
    await expect(page).toHaveURL(/\/login/);
  });

  test('should protect authenticated routes', async ({ page }) => {
    // 未認証状態でダッシュボードにアクセス
    await page.goto('/dashboard');

    // ログインページにリダイレクトされることを確認
    await expect(page).toHaveURL(/\/login/);
  });
});
