/**
 * Property-based Test Example
 *
 * プロパティベーステストは、自動生成された多数の入力値で
 * 関数のプロパティ（性質）が常に成り立つことを検証します。
 *
 * tests/property/validators.test.ts として配置してください。
 *
 * 依存パッケージ: npm install -D fast-check
 */

import fc from 'fast-check';

// テスト対象の関数（例）
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function sortNumbers(arr: number[]): number[] {
  return [...arr].sort((a, b) => a - b);
}

function reverseString(str: string): string {
  return str.split('').reverse().join('');
}

function parseQueryString(query: string): Record<string, string> {
  if (!query || query === '?') return {};

  return query
    .replace(/^\?/, '')
    .split('&')
    .filter(Boolean)
    .reduce(
      (acc, pair) => {
        const [key, value] = pair.split('=');
        if (key) {
          acc[decodeURIComponent(key)] = decodeURIComponent(value || '');
        }
        return acc;
      },
      {} as Record<string, string>,
    );
}

describe('Property-based Tests', () => {
  describe('sortNumbers', () => {
    it('ソート結果は常に昇順である', () => {
      fc.assert(
        fc.property(fc.array(fc.integer()), (arr) => {
          const sorted = sortNumbers(arr);

          // すべての隣接要素が昇順
          for (let i = 0; i < sorted.length - 1; i++) {
            expect(sorted[i]).toBeLessThanOrEqual(sorted[i + 1]);
          }
        }),
      );
    });

    it('ソート結果の長さは入力と同じ', () => {
      fc.assert(
        fc.property(fc.array(fc.integer()), (arr) => {
          const sorted = sortNumbers(arr);
          expect(sorted.length).toBe(arr.length);
        }),
      );
    });

    it('ソート結果は入力と同じ要素を含む', () => {
      fc.assert(
        fc.property(fc.array(fc.integer()), (arr) => {
          const sorted = sortNumbers(arr);

          // 各要素の出現回数が同じ
          const countOriginal = arr.reduce(
            (acc, n) => {
              acc[n] = (acc[n] || 0) + 1;
              return acc;
            },
            {} as Record<number, number>,
          );

          const countSorted = sorted.reduce(
            (acc, n) => {
              acc[n] = (acc[n] || 0) + 1;
              return acc;
            },
            {} as Record<number, number>,
          );

          expect(countOriginal).toEqual(countSorted);
        }),
      );
    });

    it('冪等性: 2回ソートしても結果は同じ', () => {
      fc.assert(
        fc.property(fc.array(fc.integer()), (arr) => {
          const sorted1 = sortNumbers(arr);
          const sorted2 = sortNumbers(sorted1);
          expect(sorted1).toEqual(sorted2);
        }),
      );
    });
  });

  describe('reverseString', () => {
    it('2回反転すると元に戻る（対合性）', () => {
      fc.assert(
        fc.property(fc.string(), (str) => {
          expect(reverseString(reverseString(str))).toBe(str);
        }),
      );
    });

    it('反転結果の長さは入力と同じ', () => {
      fc.assert(
        fc.property(fc.string(), (str) => {
          expect(reverseString(str).length).toBe(str.length);
        }),
      );
    });

    it('最初の文字は最後に、最後の文字は最初に', () => {
      fc.assert(
        fc.property(
          fc.string().filter((s) => s.length > 0),
          (str) => {
            const reversed = reverseString(str);
            expect(reversed[0]).toBe(str[str.length - 1]);
            expect(reversed[reversed.length - 1]).toBe(str[0]);
          },
        ),
      );
    });
  });

  describe('slugify', () => {
    it('結果は小文字のみ', () => {
      fc.assert(
        fc.property(fc.string(), (str) => {
          const slug = slugify(str);
          expect(slug).toBe(slug.toLowerCase());
        }),
      );
    });

    it('結果にスペースを含まない', () => {
      fc.assert(
        fc.property(fc.string(), (str) => {
          const slug = slugify(str);
          expect(slug).not.toContain(' ');
        }),
      );
    });

    it('結果は有効なURL文字のみ', () => {
      fc.assert(
        fc.property(fc.string(), (str) => {
          const slug = slugify(str);
          // 英数字、ハイフン、アンダースコアのみ
          expect(slug).toMatch(/^[a-z0-9-]*$/);
        }),
      );
    });

    it('先頭と末尾にハイフンがない', () => {
      fc.assert(
        fc.property(fc.string(), (str) => {
          const slug = slugify(str);
          if (slug.length > 0) {
            expect(slug).not.toMatch(/^-|-$/);
          }
        }),
      );
    });
  });

  describe('parseQueryString', () => {
    it('空文字列は空オブジェクトを返す', () => {
      expect(parseQueryString('')).toEqual({});
      expect(parseQueryString('?')).toEqual({});
    });

    it('キーと値のペアが正しくパースされる', () => {
      fc.assert(
        fc.property(
          fc.record({
            key: fc.string().filter((s) => s.length > 0 && !s.includes('&') && !s.includes('=')),
            value: fc.string().filter((s) => !s.includes('&') && !s.includes('=')),
          }),
          ({ key, value }) => {
            const query = `?${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
            const parsed = parseQueryString(query);
            expect(parsed[key]).toBe(value);
          },
        ),
      );
    });
  });

  describe('isValidEmail', () => {
    it('有効なメールアドレスはtrueを返す', () => {
      // 有効なメールアドレスを生成するカスタムArbitrary
      const emailArb = fc
        .record({
          local: fc.stringOf(fc.constantFrom(...'abcdefghijklmnopqrstuvwxyz0123456789'.split('')), {
            minLength: 1,
            maxLength: 10,
          }),
          domain: fc.stringOf(fc.constantFrom(...'abcdefghijklmnopqrstuvwxyz'.split('')), {
            minLength: 2,
            maxLength: 10,
          }),
          tld: fc.constantFrom('com', 'org', 'net', 'io', 'co.jp'),
        })
        .map(({ local, domain, tld }) => `${local}@${domain}.${tld}`);

      fc.assert(
        fc.property(emailArb, (email) => {
          expect(isValidEmail(email)).toBe(true);
        }),
      );
    });

    it('@がないアドレスはfalseを返す', () => {
      fc.assert(
        fc.property(
          fc.string().filter((s) => !s.includes('@')),
          (str) => {
            expect(isValidEmail(str)).toBe(false);
          },
        ),
      );
    });
  });
});

// カスタムArbitraryの例
describe('Custom Arbitraries', () => {
  // ユーザーオブジェクトのArbitrary
  const userArb = fc.record({
    id: fc.uuid(),
    name: fc.string({ minLength: 1, maxLength: 50 }),
    email: fc
      .record({
        local: fc.stringOf(fc.constantFrom(...'abcdefghijklmnopqrstuvwxyz0123456789'.split('')), {
          minLength: 1,
          maxLength: 10,
        }),
        domain: fc.stringOf(fc.constantFrom(...'abcdefghijklmnopqrstuvwxyz'.split('')), {
          minLength: 2,
          maxLength: 10,
        }),
      })
      .map(({ local, domain }) => `${local}@${domain}.com`),
    age: fc.integer({ min: 0, max: 150 }),
    isActive: fc.boolean(),
  });

  it('ユーザーオブジェクトの検証', () => {
    fc.assert(
      fc.property(userArb, (user) => {
        expect(user.id).toBeDefined();
        expect(user.name.length).toBeGreaterThan(0);
        expect(user.email).toContain('@');
        expect(user.age).toBeGreaterThanOrEqual(0);
        expect(typeof user.isActive).toBe('boolean');
      }),
    );
  });
});
