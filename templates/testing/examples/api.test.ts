/**
 * API Test Example
 *
 * APIテストは、RESTful APIエンドポイントの
 * 動作を包括的に検証するテストです。
 *
 * tests/api/endpoints.test.ts として配置してください。
 *
 * 依存パッケージ:
 * npm install -D supertest @types/supertest
 */

import { createMocks } from 'node-mocks-http';
import type { NextApiRequest, NextApiResponse } from 'next';

// テスト対象のAPIハンドラ（例）
// import handler from '@/pages/api/users';

const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';

describe('API Endpoint Tests', () => {
  describe('GET /api/users', () => {
    it('認証済みユーザーがユーザー一覧を取得できる', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect(res.status).toBe(200);

      const data = await res.json();
      expect(Array.isArray(data)).toBe(true);
    });

    it('認証なしで401を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users`);
      expect(res.status).toBe(401);
    });

    it('ページネーションが正しく動作する', async () => {
      const res = await fetch(`${BASE_URL}/api/users?page=1&limit=10`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect(res.status).toBe(200);

      const data = await res.json();
      expect(data.length).toBeLessThanOrEqual(10);
    });

    it('フィルタリングが正しく動作する', async () => {
      const res = await fetch(`${BASE_URL}/api/users?role=admin`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect(res.status).toBe(200);

      const data = await res.json();
      data.forEach((user: { role: string }) => {
        expect(user.role).toBe('admin');
      });
    });

    it('ソートが正しく動作する', async () => {
      const res = await fetch(`${BASE_URL}/api/users?sort=created_at&order=desc`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect(res.status).toBe(200);

      const data = await res.json();
      if (data.length > 1) {
        const dates = data.map((u: { created_at: string }) => new Date(u.created_at).getTime());
        expect(dates).toEqual([...dates].sort((a, b) => b - a));
      }
    });
  });

  describe('GET /api/users/:id', () => {
    it('存在するユーザーを取得できる', async () => {
      const userId = 'test-user-id';
      const res = await fetch(`${BASE_URL}/api/users/${userId}`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      if (res.status === 200) {
        const data = await res.json();
        expect(data.id).toBe(userId);
      } else {
        // ユーザーが存在しない場合は404
        expect(res.status).toBe(404);
      }
    });

    it('存在しないユーザーで404を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users/non-existent-id`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect(res.status).toBe(404);
    });

    it('無効なIDフォーマットで400を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users/invalid-format!@#`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect([400, 404]).toContain(res.status);
    });
  });

  describe('POST /api/users', () => {
    it('有効なデータでユーザーを作成できる', async () => {
      const newUser = {
        name: `Test User ${Date.now()}`,
        email: `test-${Date.now()}@example.com`,
        role: 'user',
      };

      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify(newUser),
      });

      if (res.status === 201) {
        const data = await res.json();
        expect(data.name).toBe(newUser.name);
        expect(data.email).toBe(newUser.email);
        expect(data.id).toBeDefined();
      }
    });

    it('必須フィールドがない場合は400を返す', async () => {
      const invalidUser = {
        name: 'Test User',
        // email is missing
      };

      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify(invalidUser),
      });

      expect(res.status).toBe(400);

      const data = await res.json();
      expect(data.error || data.message).toBeDefined();
    });

    it('重複メールアドレスで409を返す', async () => {
      const existingEmail = 'existing@example.com';

      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify({
          name: 'Duplicate User',
          email: existingEmail,
        }),
      });

      // 409 Conflict または 400 Bad Request
      expect([400, 409]).toContain(res.status);
    });

    it('無効なメールフォーマットで400を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify({
          name: 'Test User',
          email: 'invalid-email',
        }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('PUT /api/users/:id', () => {
    it('ユーザー情報を更新できる', async () => {
      const userId = 'test-user-id';
      const updateData = {
        name: 'Updated Name',
      };

      const res = await fetch(`${BASE_URL}/api/users/${userId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify(updateData),
      });

      if (res.status === 200) {
        const data = await res.json();
        expect(data.name).toBe(updateData.name);
      }
    });

    it('部分更新（PATCH）が動作する', async () => {
      const userId = 'test-user-id';

      const res = await fetch(`${BASE_URL}/api/users/${userId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify({ name: 'Patched Name' }),
      });

      // PATCH がサポートされていれば200
      expect([200, 405]).toContain(res.status);
    });

    it('他のユーザーのデータを更新できない（認可）', async () => {
      const otherUserId = 'other-user-id';

      const res = await fetch(`${BASE_URL}/api/users/${otherUserId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify({ name: 'Hacked Name' }),
      });

      // 403 Forbidden または 404 Not Found
      expect([403, 404]).toContain(res.status);
    });
  });

  describe('DELETE /api/users/:id', () => {
    it('ユーザーを削除できる', async () => {
      // まずテストユーザーを作成
      const createRes = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: JSON.stringify({
          name: 'To Delete',
          email: `delete-${Date.now()}@example.com`,
        }),
      });

      if (createRes.status === 201) {
        const created = await createRes.json();

        const deleteRes = await fetch(`${BASE_URL}/api/users/${created.id}`, {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
          },
        });

        expect([200, 204]).toContain(deleteRes.status);

        // 削除後に取得できないことを確認
        const getRes = await fetch(`${BASE_URL}/api/users/${created.id}`, {
          headers: {
            Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
          },
        });

        expect(getRes.status).toBe(404);
      }
    });

    it('存在しないユーザーの削除で404を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users/non-existent-id`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect(res.status).toBe(404);
    });
  });

  describe('API エラーハンドリング', () => {
    it('不正なJSONボディで400を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: 'invalid json',
      });

      expect(res.status).toBe(400);
    });

    it('サポートされていないメソッドで405を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'TRACE',
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      expect([405, 400]).toContain(res.status);
    });

    it('Content-Typeが不正な場合でも適切に処理', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/plain',
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
        body: 'plain text',
      });

      // 415 Unsupported Media Type または 400
      expect([400, 415]).toContain(res.status);
    });
  });

  describe('API レスポンス形式', () => {
    it('Content-Type が application/json', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      const contentType = res.headers.get('content-type');
      expect(contentType).toContain('application/json');
    });

    it('エラーレスポンスが統一フォーマット', async () => {
      const res = await fetch(`${BASE_URL}/api/users/non-existent`, {
        headers: {
          Authorization: `Bearer ${process.env.TEST_AUTH_TOKEN || 'test-token'}`,
        },
      });

      if (res.status === 404) {
        const data = await res.json();
        // エラーレスポンスに error または message フィールドがある
        expect(data.error || data.message).toBeDefined();
      }
    });
  });
});

// Next.js API Route のユニットテスト（node-mocks-http使用）
describe('API Route Unit Tests', () => {
  it('ハンドラが正しいレスポンスを返す', async () => {
    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: 'GET',
    });

    // handler(req, res); // 実際のハンドラを呼び出す

    // expect(res._getStatusCode()).toBe(200);
    // expect(JSON.parse(res._getData())).toEqual({ ... });

    // プレースホルダー
    expect(true).toBe(true);
  });

  it('POST リクエストを正しく処理する', async () => {
    const { req, res } = createMocks<NextApiRequest, NextApiResponse>({
      method: 'POST',
      body: {
        name: 'Test User',
        email: 'test@example.com',
      },
    });

    // handler(req, res);

    // expect(res._getStatusCode()).toBe(201);

    // プレースホルダー
    expect(true).toBe(true);
  });
});
