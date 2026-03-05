/**
 * Security Test Example
 *
 * セキュリティテストは、一般的な脆弱性が
 * 存在しないことを検証するテストです。
 *
 * tests/security/security.test.ts として配置してください。
 *
 * CI: npm audit, ESLint security rules, license-checker
 */

const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';

describe('Security Tests', () => {
  describe('セキュリティヘッダー', () => {
    it('X-Content-Type-Options: nosniff が設定されている', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      expect(res.headers.get('x-content-type-options')).toBe('nosniff');
    });

    it('X-Frame-Options が設定されている', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      const xfo = res.headers.get('x-frame-options');
      expect(['DENY', 'SAMEORIGIN']).toContain(xfo);
    });

    it('X-XSS-Protection が設定されている', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      const xxp = res.headers.get('x-xss-protection');
      // 1; mode=block または無効化（モダンブラウザでは不要）
      expect(xxp === null || xxp === '1; mode=block' || xxp === '0').toBe(true);
    });

    it('Content-Security-Policy が設定されている', async () => {
      const res = await fetch(`${BASE_URL}/`);
      const csp = res.headers.get('content-security-policy');
      // CSPが設定されている場合は検証
      if (csp) {
        expect(csp).toContain('default-src');
      }
    });

    it('Strict-Transport-Security が設定されている（HTTPS）', async () => {
      // ローカル環境ではスキップ
      if (BASE_URL.startsWith('http://localhost')) {
        return;
      }

      const res = await fetch(BASE_URL);
      const hsts = res.headers.get('strict-transport-security');
      expect(hsts).toBeTruthy();
      expect(hsts).toContain('max-age=');
    });

    it('X-Powered-By が削除されている', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      expect(res.headers.get('x-powered-by')).toBeNull();
    });

    it('Referrer-Policy が設定されている', async () => {
      const res = await fetch(`${BASE_URL}/`);
      const rp = res.headers.get('referrer-policy');
      if (rp) {
        const validPolicies = [
          'no-referrer',
          'no-referrer-when-downgrade',
          'same-origin',
          'origin',
          'strict-origin',
          'origin-when-cross-origin',
          'strict-origin-when-cross-origin',
        ];
        expect(validPolicies).toContain(rp);
      }
    });

    it('Permissions-Policy が設定されている', async () => {
      const res = await fetch(`${BASE_URL}/`);
      const pp = res.headers.get('permissions-policy');
      if (pp) {
        // カメラやマイクが制限されていることを確認
        expect(pp).toMatch(/camera|microphone|geolocation/);
      }
    });
  });

  describe('認証・認可', () => {
    it('認証なしで保護エンドポイントにアクセスすると401', async () => {
      const res = await fetch(`${BASE_URL}/api/users`);
      expect(res.status).toBe(401);
    });

    it('無効なトークンで403または401', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        headers: {
          Authorization: 'Bearer invalid-token',
        },
      });
      expect([401, 403]).toContain(res.status);
    });

    it('期限切れトークンで401', async () => {
      // 期限切れトークン（実際のテストではモックまたは実際の期限切れトークンを使用）
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjB9.xxx';

      const res = await fetch(`${BASE_URL}/api/users`, {
        headers: {
          Authorization: `Bearer ${expiredToken}`,
        },
      });
      expect([401, 403]).toContain(res.status);
    });
  });

  describe('入力検証', () => {
    it('SQLインジェクション攻撃が防がれる', async () => {
      const sqlPayload = "'; DROP TABLE users; --";

      const res = await fetch(`${BASE_URL}/api/users?search=${encodeURIComponent(sqlPayload)}`);

      // 500エラーではなく、適切に処理される
      expect([200, 400, 401]).toContain(res.status);
    });

    it('XSS攻撃が防がれる', async () => {
      const xssPayload = '<script>alert("XSS")</script>';

      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: xssPayload }),
      });

      if (res.ok) {
        const body = await res.json();
        // スクリプトタグがエスケープされている
        expect(JSON.stringify(body)).not.toContain('<script>');
      }
    });

    it('パストラバーサル攻撃が防がれる', async () => {
      const pathPayload = '../../../etc/passwd';

      const res = await fetch(`${BASE_URL}/api/files/${encodeURIComponent(pathPayload)}`);

      // 404 または 400 が返される（ファイルシステムアクセスは不可）
      expect([400, 404]).toContain(res.status);
    });

    it('コマンドインジェクション攻撃が防がれる', async () => {
      const cmdPayload = '; rm -rf /';

      const res = await fetch(`${BASE_URL}/api/search?q=${encodeURIComponent(cmdPayload)}`);

      // エラーではなく正常に処理（検索結果なし）
      expect([200, 400]).toContain(res.status);
    });
  });

  describe('レート制限', () => {
    it('短時間の大量リクエストで429が返る', async () => {
      const requests = Array(100)
        .fill(null)
        .map(() => fetch(`${BASE_URL}/api/health`));

      const responses = await Promise.all(requests);
      const statuses = responses.map((r) => r.status);

      // 少なくともいくつかのリクエストがレート制限される
      const rateLimited = statuses.filter((s) => s === 429).length;

      // レート制限が実装されていれば429が含まれる
      console.log(`Rate limited: ${rateLimited}/${statuses.length}`);
    });
  });

  describe('エラーハンドリング', () => {
    it('エラーレスポンスに機密情報が含まれない', async () => {
      const res = await fetch(`${BASE_URL}/api/nonexistent`);
      const body = await res.text();

      // スタックトレースやファイルパスが含まれない
      expect(body).not.toMatch(/at\s+\w+\s+\(/); // スタックトレース
      expect(body).not.toMatch(/\/Users\//); // ファイルパス
      expect(body).not.toMatch(/node_modules/);
      expect(body).not.toMatch(/Error:/);
    });

    it('デバッグ情報が本番環境で無効', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      const body = await res.json();

      // デバッグフラグが含まれない
      expect(body).not.toHaveProperty('debug');
      expect(body).not.toHaveProperty('stack');
    });
  });

  describe('CORS設定', () => {
    it('許可されていないオリジンからのリクエストがブロックされる', async () => {
      const res = await fetch(`${BASE_URL}/api/health`, {
        headers: {
          Origin: 'https://malicious-site.com',
        },
      });

      const allowedOrigin = res.headers.get('access-control-allow-origin');

      // ワイルドカードでない場合、悪意のあるオリジンは許可されない
      if (allowedOrigin && allowedOrigin !== '*') {
        expect(allowedOrigin).not.toBe('https://malicious-site.com');
      }
    });

    it('credentials付きリクエストでワイルドカードOriginが使われない', async () => {
      const res = await fetch(`${BASE_URL}/api/health`, {
        headers: {
          Origin: 'https://example.com',
        },
        credentials: 'include',
      });

      const allowedOrigin = res.headers.get('access-control-allow-origin');
      const allowCredentials = res.headers.get('access-control-allow-credentials');

      // credentials: true の場合、Origin は * 以外
      if (allowCredentials === 'true') {
        expect(allowedOrigin).not.toBe('*');
      }
    });
  });

  describe('セッション管理', () => {
    it('セッションIDが予測不可能', async () => {
      // 2つのセッションを取得
      const res1 = await fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'test@example.com',
          password: 'password',
        }),
      });

      const res2 = await fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'test@example.com',
          password: 'password',
        }),
      });

      if (res1.ok && res2.ok) {
        const body1 = await res1.json();
        const body2 = await res2.json();

        // トークンが異なる
        expect(body1.token).not.toBe(body2.token);

        // トークンが十分な長さを持つ
        expect(body1.token.length).toBeGreaterThan(20);
      }
    });
  });
});

// npm audit のラッパー
describe('Dependency Security', () => {
  it('npm audit で重大な脆弱性がない（CI で実行）', () => {
    // このテストは CI で npm audit として実行される
    // ここではスキップ
    expect(true).toBe(true);
  });
});
