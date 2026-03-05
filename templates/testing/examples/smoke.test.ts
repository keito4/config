/**
 * API Smoke Test Example
 *
 * スモークテストは、システムの基本的な動作を確認するテストです。
 * 本番環境へのデプロイ前後に実行し、基本機能が動作していることを確認します。
 *
 * tests/regression/api-smoke.test.ts として配置してください。
 */

const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';

describe('API Smoke Tests', () => {
  describe('ヘルスチェック', () => {
    it('GET /api/health → 200, status: healthy', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.status).toBe('healthy');
    });

    it('HEAD /api/health → 200', async () => {
      const res = await fetch(`${BASE_URL}/api/health`, {
        method: 'HEAD',
      });
      expect(res.status).toBe(200);
    });
  });

  describe('認証エンドポイント（未認証）', () => {
    it('GET /api/protected（認証なし）→ 401', async () => {
      const res = await fetch(`${BASE_URL}/api/protected`);
      expect(res.status).toBe(401);

      const body = await res.json();
      expect(body.error).toBeDefined();
    });

    it('POST /api/admin/users（認証なし）→ 401', async () => {
      const res = await fetch(`${BASE_URL}/api/admin/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'test' }),
      });
      expect(res.status).toBe(401);
    });
  });

  describe('セキュリティヘッダー', () => {
    it('レスポンスに必須セキュリティヘッダーが含まれる', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);

      // X-Content-Type-Options
      expect(res.headers.get('x-content-type-options')).toBe('nosniff');

      // X-Frame-Options
      expect(res.headers.get('x-frame-options')).toBe('SAMEORIGIN');
    });

    it('X-Powered-By が存在しない（情報漏洩防止）', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      expect(res.headers.get('x-powered-by')).toBeNull();
    });
  });

  describe('エラーハンドリング', () => {
    it('存在しないAPIエンドポイント → 404', async () => {
      const res = await fetch(`${BASE_URL}/api/nonexistent-endpoint-12345`);
      expect(res.status).toBe(404);
    });

    it('不正なJSONボディ → 400', async () => {
      const res = await fetch(`${BASE_URL}/api/example`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: 'invalid json',
      });
      // 400 または 500（実装による）
      expect([400, 500]).toContain(res.status);
    });
  });

  describe('レスポンス形式', () => {
    it('APIレスポンスはJSON形式', async () => {
      const res = await fetch(`${BASE_URL}/api/health`);
      const contentType = res.headers.get('content-type');
      expect(contentType).toContain('application/json');
    });
  });
});
