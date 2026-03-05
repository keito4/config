/**
 * i18n (Internationalization) Test Example
 *
 * 国際化テストは、多言語対応が正しく動作するかを検証します。
 *
 * tests/i18n/translations.test.tsx として配置してください。
 *
 * 依存パッケージ:
 * npm install -D @testing-library/react next-intl (または i18next)
 */

import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// 翻訳ファイルの例
const translations = {
  ja: {
    common: {
      welcome: 'ようこそ',
      login: 'ログイン',
      logout: 'ログアウト',
      save: '保存',
      cancel: 'キャンセル',
      delete: '削除',
      edit: '編集',
      loading: '読み込み中...',
      error: 'エラーが発生しました',
      success: '成功しました',
    },
    auth: {
      email: 'メールアドレス',
      password: 'パスワード',
      forgotPassword: 'パスワードをお忘れですか？',
      signUp: 'アカウント作成',
      signIn: 'ログイン',
    },
    validation: {
      required: '必須項目です',
      email: '有効なメールアドレスを入力してください',
      minLength: '{count}文字以上で入力してください',
      maxLength: '{count}文字以内で入力してください',
    },
  },
  en: {
    common: {
      welcome: 'Welcome',
      login: 'Login',
      logout: 'Logout',
      save: 'Save',
      cancel: 'Cancel',
      delete: 'Delete',
      edit: 'Edit',
      loading: 'Loading...',
      error: 'An error occurred',
      success: 'Success',
    },
    auth: {
      email: 'Email',
      password: 'Password',
      forgotPassword: 'Forgot password?',
      signUp: 'Sign Up',
      signIn: 'Sign In',
    },
    validation: {
      required: 'This field is required',
      email: 'Please enter a valid email address',
      minLength: 'Must be at least {count} characters',
      maxLength: 'Must be at most {count} characters',
    },
  },
};

// サポートする言語
const SUPPORTED_LOCALES = ['ja', 'en'] as const;
type Locale = (typeof SUPPORTED_LOCALES)[number];

describe('i18n Tests', () => {
  describe('翻訳ファイル検証', () => {
    it('すべての言語で同じキーが存在する', () => {
      const getKeys = (obj: Record<string, unknown>, prefix = ''): string[] => {
        return Object.entries(obj).flatMap(([key, value]) => {
          const fullKey = prefix ? `${prefix}.${key}` : key;
          if (typeof value === 'object' && value !== null) {
            return getKeys(value as Record<string, unknown>, fullKey);
          }
          return [fullKey];
        });
      };

      const jaKeys = getKeys(translations.ja).sort();
      const enKeys = getKeys(translations.en).sort();

      expect(jaKeys).toEqual(enKeys);
    });

    it('翻訳値が空でない', () => {
      const checkNotEmpty = (obj: Record<string, unknown>, locale: string, path = ''): void => {
        Object.entries(obj).forEach(([key, value]) => {
          const fullPath = path ? `${path}.${key}` : key;
          if (typeof value === 'object' && value !== null) {
            checkNotEmpty(value as Record<string, unknown>, locale, fullPath);
          } else {
            expect(value).not.toBe('');
            if (typeof value === 'string' && value.trim() === '') {
              throw new Error(`Empty translation: ${locale}.${fullPath}`);
            }
          }
        });
      };

      SUPPORTED_LOCALES.forEach((locale) => {
        checkNotEmpty(translations[locale], locale);
      });
    });

    it('プレースホルダーが正しいフォーマット', () => {
      const checkPlaceholders = (obj: Record<string, unknown>, path = ''): void => {
        Object.entries(obj).forEach(([key, value]) => {
          const fullPath = path ? `${path}.${key}` : key;
          if (typeof value === 'object' && value !== null) {
            checkPlaceholders(value as Record<string, unknown>, fullPath);
          } else if (typeof value === 'string') {
            // {name} 形式のプレースホルダーを検出
            const placeholders = value.match(/\{[^}]+\}/g) || [];
            placeholders.forEach((placeholder) => {
              // 有効な変数名であることを確認
              const varName = placeholder.slice(1, -1);
              expect(varName).toMatch(/^[a-zA-Z_][a-zA-Z0-9_]*$/);
            });
          }
        });
      };

      SUPPORTED_LOCALES.forEach((locale) => {
        checkPlaceholders(translations[locale]);
      });
    });

    it('プレースホルダーがすべての言語で一致する', () => {
      const getPlaceholders = (str: string): string[] => {
        const matches = str.match(/\{[^}]+\}/g) || [];
        return matches.sort();
      };

      const getValue = (obj: Record<string, unknown>, path: string): string | null => {
        const keys = path.split('.');
        let current: unknown = obj;
        for (const key of keys) {
          if (typeof current !== 'object' || current === null) return null;
          current = (current as Record<string, unknown>)[key];
        }
        return typeof current === 'string' ? current : null;
      };

      const getKeys = (obj: Record<string, unknown>, prefix = ''): string[] => {
        return Object.entries(obj).flatMap(([key, value]) => {
          const fullKey = prefix ? `${prefix}.${key}` : key;
          if (typeof value === 'object' && value !== null) {
            return getKeys(value as Record<string, unknown>, fullKey);
          }
          return [fullKey];
        });
      };

      const allKeys = getKeys(translations.ja);

      allKeys.forEach((key) => {
        const jaValue = getValue(translations.ja, key);
        const enValue = getValue(translations.en, key);

        if (jaValue && enValue) {
          const jaPlaceholders = getPlaceholders(jaValue);
          const enPlaceholders = getPlaceholders(enValue);
          expect(jaPlaceholders).toEqual(enPlaceholders);
        }
      });
    });
  });

  describe('翻訳品質検証', () => {
    it('英語の翻訳が日本語のみではない', () => {
      const checkNoJapanese = (obj: Record<string, unknown>, path = ''): void => {
        Object.entries(obj).forEach(([key, value]) => {
          const fullPath = path ? `${path}.${key}` : key;
          if (typeof value === 'object' && value !== null) {
            checkNoJapanese(value as Record<string, unknown>, fullPath);
          } else if (typeof value === 'string') {
            // 日本語文字（ひらがな、カタカナ、漢字）が含まれていないことを確認
            const hasJapanese = /[\u3040-\u309f\u30a0-\u30ff\u4e00-\u9faf]/.test(value);
            if (hasJapanese) {
              console.warn(`Japanese characters in EN translation: ${fullPath}`);
            }
            expect(hasJapanese).toBe(false);
          }
        });
      };

      checkNoJapanese(translations.en);
    });

    it('日本語の翻訳が英語のみではない', () => {
      const checkHasJapanese = (obj: Record<string, unknown>, path = ''): void => {
        Object.entries(obj).forEach(([key, value]) => {
          const fullPath = path ? `${path}.${key}` : key;
          if (typeof value === 'object' && value !== null) {
            checkHasJapanese(value as Record<string, unknown>, fullPath);
          } else if (typeof value === 'string') {
            // 短い文字列（略語など）を除外
            if (value.length > 3) {
              const hasJapanese = /[\u3040-\u309f\u30a0-\u30ff\u4e00-\u9faf]/.test(value);
              if (!hasJapanese) {
                console.warn(`No Japanese characters in JA translation: ${fullPath} = "${value}"`);
              }
            }
          }
        });
      };

      checkHasJapanese(translations.ja);
    });
  });

  describe('ロケール切り替え', () => {
    // モックの翻訳プロバイダー
    const MockI18nProvider: React.FC<{
      locale: Locale;
      children: React.ReactNode;
    }> = ({ locale, children }) => {
      return <div data-locale={locale}>{children}</div>;
    };

    // 翻訳を取得するユーティリティ
    const t = (locale: Locale, key: string): string => {
      const keys = key.split('.');
      let current: unknown = translations[locale];
      for (const k of keys) {
        if (typeof current !== 'object' || current === null) return key;
        current = (current as Record<string, unknown>)[k];
      }
      return typeof current === 'string' ? current : key;
    };

    // テスト用コンポーネント
    const TestComponent: React.FC<{ locale: Locale }> = ({ locale }) => {
      return (
        <MockI18nProvider locale={locale}>
          <h1>{t(locale, 'common.welcome')}</h1>
          <button>{t(locale, 'common.login')}</button>
        </MockI18nProvider>
      );
    };

    it('日本語表示が正しい', () => {
      render(<TestComponent locale="ja" />);

      expect(screen.getByRole('heading')).toHaveTextContent('ようこそ');
      expect(screen.getByRole('button')).toHaveTextContent('ログイン');
    });

    it('英語表示が正しい', () => {
      render(<TestComponent locale="en" />);

      expect(screen.getByRole('heading')).toHaveTextContent('Welcome');
      expect(screen.getByRole('button')).toHaveTextContent('Login');
    });
  });

  describe('日付・数値フォーマット', () => {
    it('日付が正しくフォーマットされる（日本語）', () => {
      const date = new Date('2024-01-15T10:30:00');

      const formatted = new Intl.DateTimeFormat('ja-JP', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      }).format(date);

      expect(formatted).toBe('2024年1月15日');
    });

    it('日付が正しくフォーマットされる（英語）', () => {
      const date = new Date('2024-01-15T10:30:00');

      const formatted = new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      }).format(date);

      expect(formatted).toBe('January 15, 2024');
    });

    it('通貨が正しくフォーマットされる', () => {
      const amount = 1234567.89;

      const jaFormatted = new Intl.NumberFormat('ja-JP', {
        style: 'currency',
        currency: 'JPY',
      }).format(amount);

      const enFormatted = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      }).format(amount);

      expect(jaFormatted).toContain('1,234,568'); // 円は小数点以下なし
      expect(enFormatted).toContain('1,234,567.89');
    });

    it('パーセントが正しくフォーマットされる', () => {
      const value = 0.1234;

      const jaFormatted = new Intl.NumberFormat('ja-JP', {
        style: 'percent',
        minimumFractionDigits: 1,
      }).format(value);

      const enFormatted = new Intl.NumberFormat('en-US', {
        style: 'percent',
        minimumFractionDigits: 1,
      }).format(value);

      expect(jaFormatted).toBe('12.3%');
      expect(enFormatted).toBe('12.3%');
    });
  });

  describe('複数形・性別対応', () => {
    it('複数形が正しく処理される', () => {
      const pluralRules = {
        ja: (count: number) => {
          // 日本語は数による変化なし
          return `${count}件のメッセージ`;
        },
        en: (count: number) => {
          if (count === 0) return 'No messages';
          if (count === 1) return '1 message';
          return `${count} messages`;
        },
      };

      expect(pluralRules.ja(0)).toBe('0件のメッセージ');
      expect(pluralRules.ja(1)).toBe('1件のメッセージ');
      expect(pluralRules.ja(5)).toBe('5件のメッセージ');

      expect(pluralRules.en(0)).toBe('No messages');
      expect(pluralRules.en(1)).toBe('1 message');
      expect(pluralRules.en(5)).toBe('5 messages');
    });

    it('Intl.PluralRules が正しく動作する', () => {
      const jaRules = new Intl.PluralRules('ja-JP');
      const enRules = new Intl.PluralRules('en-US');

      // 日本語は常に "other"
      expect(jaRules.select(1)).toBe('other');
      expect(jaRules.select(2)).toBe('other');

      // 英語は 1 が "one"、それ以外は "other"
      expect(enRules.select(1)).toBe('one');
      expect(enRules.select(2)).toBe('other');
    });
  });

  describe('RTL (Right-to-Left) 対応', () => {
    it('RTL言語の方向が正しく設定される', () => {
      const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
      const ltrLanguages = ['ja', 'en', 'zh', 'ko'];

      const getDirection = (locale: string): 'rtl' | 'ltr' => {
        return rtlLanguages.includes(locale.split('-')[0]) ? 'rtl' : 'ltr';
      };

      expect(getDirection('ar-SA')).toBe('rtl');
      expect(getDirection('he-IL')).toBe('rtl');
      expect(getDirection('ja-JP')).toBe('ltr');
      expect(getDirection('en-US')).toBe('ltr');
    });
  });

  describe('エスケープ・XSS対策', () => {
    it('翻訳文字列にHTMLが含まれない', () => {
      const checkNoHtml = (obj: Record<string, unknown>, path = ''): void => {
        Object.entries(obj).forEach(([key, value]) => {
          const fullPath = path ? `${path}.${key}` : key;
          if (typeof value === 'object' && value !== null) {
            checkNoHtml(value as Record<string, unknown>, fullPath);
          } else if (typeof value === 'string') {
            // HTMLタグが含まれていないことを確認
            const hasHtml = /<[^>]+>/.test(value);
            if (hasHtml) {
              console.warn(`HTML in translation: ${fullPath}`);
            }
            expect(hasHtml).toBe(false);
          }
        });
      };

      SUPPORTED_LOCALES.forEach((locale) => {
        checkNoHtml(translations[locale]);
      });
    });
  });
});
