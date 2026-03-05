import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright Configuration for Regression Tests
 *
 * リグレッションテスト用の設定。
 * 本番環境に近い条件でテストを実行する。
 */
export default defineConfig({
  testDir: './tests/regression',
  testMatch: '**/*.spec.ts',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  // リグレッションテストは安定性重視でワーカー数を制限
  workers: process.env.CI ? 2 : undefined,
  reporter: process.env.CI ? [['html'], ['list']] : 'list',
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
