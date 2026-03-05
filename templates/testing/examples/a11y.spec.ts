/**
 * Accessibility Test Example
 *
 * アクセシビリティテストは、WCAG 2.1 ガイドラインに
 * 準拠しているかを確認するテストです。
 *
 * tests/a11y/pages.spec.ts として配置してください。
 *
 * 依存パッケージ: npm install -D @axe-core/playwright
 */

import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('アクセシビリティテスト', () => {
  test.describe('認証ページ', () => {
    test('ログインページがWCAG 2.1 AAに準拠している', async ({ page }) => {
      await page.goto('/login');
      await page.waitForLoadState('networkidle');

      const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();

      // 違反がないことを確認
      expect(results.violations).toEqual([]);
    });

    test('新規登録ページがWCAG 2.1 AAに準拠している', async ({ page }) => {
      await page.goto('/signup');
      await page.waitForLoadState('networkidle');

      const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();

      expect(results.violations).toEqual([]);
    });
  });

  test.describe('フォーム要素', () => {
    test('すべてのフォーム要素にラベルがある', async ({ page }) => {
      await page.goto('/login');

      // input要素を取得
      const inputs = await page.locator('input').all();

      for (const input of inputs) {
        const id = await input.getAttribute('id');
        const ariaLabel = await input.getAttribute('aria-label');
        const ariaLabelledby = await input.getAttribute('aria-labelledby');
        const placeholder = await input.getAttribute('placeholder');

        // id に対応する label、または aria-label/aria-labelledby があることを確認
        let hasLabel = false;

        if (id) {
          const label = await page.locator(`label[for="${id}"]`);
          hasLabel = (await label.count()) > 0;
        }

        expect(
          hasLabel || ariaLabel || ariaLabelledby,
          `Input ${id || 'unknown'} should have a label or aria-label`,
        ).toBeTruthy();
      }
    });

    test('フォームエラーがスクリーンリーダーに通知される', async ({ page }) => {
      await page.goto('/login');

      // 空のフォームを送信
      await page.getByRole('button', { name: /ログイン/i }).click();

      // エラーメッセージが aria-live または role="alert" を持っている
      const errorMessage = page.locator('[role="alert"], [aria-live="polite"], [aria-live="assertive"]');
      await expect(errorMessage.first()).toBeVisible();
    });
  });

  test.describe('キーボードナビゲーション', () => {
    test('Tabキーですべてのインタラクティブ要素にアクセスできる', async ({ page }) => {
      await page.goto('/login');

      const interactiveElements = await page
        .locator('button, a[href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
        .all();

      // 最初の要素にフォーカス
      await page.keyboard.press('Tab');

      for (let i = 0; i < interactiveElements.length; i++) {
        // フォーカスがある要素を取得
        const focusedElement = await page.evaluate(() => {
          const el = document.activeElement;
          return el ? el.tagName.toLowerCase() : null;
        });

        expect(focusedElement).toBeTruthy();

        // 次の要素にフォーカスを移動
        await page.keyboard.press('Tab');
      }
    });

    test('Escキーでモーダルを閉じることができる', async ({ page }) => {
      await page.goto('/dashboard');

      // モーダルを開く（例）
      await page.getByRole('button', { name: /新規作成/i }).click();

      // モーダルが表示される
      const modal = page.locator('[role="dialog"]');
      await expect(modal).toBeVisible();

      // Escキーで閉じる
      await page.keyboard.press('Escape');

      // モーダルが閉じる
      await expect(modal).not.toBeVisible();
    });
  });

  test.describe('コントラスト比', () => {
    test('テキストのコントラスト比がWCAG AA基準を満たす', async ({ page }) => {
      await page.goto('/login');

      const results = await new AxeBuilder({ page }).withRules(['color-contrast']).analyze();

      expect(results.violations).toEqual([]);
    });
  });

  test.describe('スクリーンリーダー対応', () => {
    test('ページにメインランドマークがある', async ({ page }) => {
      await page.goto('/dashboard');

      const main = await page.locator('main, [role="main"]');
      await expect(main).toBeVisible();
    });

    test('見出し構造が正しい', async ({ page }) => {
      await page.goto('/dashboard');

      // h1が1つだけ存在する
      const h1Count = await page.locator('h1').count();
      expect(h1Count).toBe(1);

      // 見出しレベルがスキップされていない
      const headings = await page.locator('h1, h2, h3, h4, h5, h6').all();
      let lastLevel = 0;

      for (const heading of headings) {
        const tagName = await heading.evaluate((el) => el.tagName);
        const level = parseInt(tagName.replace('H', ''));

        // レベルが1より大きくスキップされていない
        expect(level - lastLevel).toBeLessThanOrEqual(1);
        lastLevel = level;
      }
    });

    test('画像に代替テキストがある', async ({ page }) => {
      await page.goto('/dashboard');

      const images = await page.locator('img').all();

      for (const img of images) {
        const alt = await img.getAttribute('alt');
        const role = await img.getAttribute('role');

        // alt属性があるか、role="presentation"で装飾画像として扱われている
        expect(
          alt !== null || role === 'presentation',
          'Images should have alt text or role="presentation"',
        ).toBeTruthy();
      }
    });
  });

  test.describe('フォーカス表示', () => {
    test('フォーカス状態が視覚的に識別できる', async ({ page }) => {
      await page.goto('/login');

      // 最初のinputにフォーカス
      await page.keyboard.press('Tab');

      const focusedElement = page.locator(':focus');
      const outlineStyle = await focusedElement.evaluate((el) => {
        const styles = window.getComputedStyle(el);
        return {
          outline: styles.outline,
          boxShadow: styles.boxShadow,
        };
      });

      // outline または box-shadow でフォーカスが視覚的に表示されている
      const hasVisibleFocus =
        (outlineStyle.outline && outlineStyle.outline !== 'none') ||
        (outlineStyle.boxShadow && outlineStyle.boxShadow !== 'none');

      expect(hasVisibleFocus).toBe(true);
    });
  });
});
