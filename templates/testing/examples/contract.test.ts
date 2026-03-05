/**
 * Contract Test Example
 *
 * API契約テストは、APIが仕様（OpenAPI/Swagger）に
 * 準拠しているかを検証するテストです。
 *
 * tests/contract/api-contract.test.ts として配置してください。
 *
 * 依存パッケージ:
 * npm install -D openapi-typescript openapi-fetch
 */

import { describe, it, expect, beforeAll } from '@jest/globals';

// OpenAPI仕様から生成された型（npx openapi-typescript で生成）
// import type { paths, components } from '@/lib/types/api';

const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';

// API仕様のスキーマ定義（実際はOpenAPIから生成）
const apiSpec = {
  '/api/users': {
    get: {
      responses: {
        200: {
          schema: {
            type: 'array',
            items: {
              type: 'object',
              required: ['id', 'email', 'name'],
              properties: {
                id: { type: 'string', format: 'uuid' },
                email: { type: 'string', format: 'email' },
                name: { type: 'string' },
                createdAt: { type: 'string', format: 'date-time' },
              },
            },
          },
        },
      },
    },
    post: {
      requestBody: {
        required: ['email', 'name'],
        properties: {
          email: { type: 'string', format: 'email' },
          name: { type: 'string', minLength: 1 },
        },
      },
      responses: {
        201: {
          schema: {
            type: 'object',
            required: ['id', 'email', 'name'],
          },
        },
        400: {
          schema: {
            type: 'object',
            required: ['error'],
          },
        },
      },
    },
  },
  '/api/users/{id}': {
    get: {
      responses: {
        200: {
          schema: {
            type: 'object',
            required: ['id', 'email', 'name'],
          },
        },
        404: {
          schema: {
            type: 'object',
            required: ['error'],
          },
        },
      },
    },
  },
};

// スキーマバリデーションヘルパー
function validateSchema(data: unknown, schema: Record<string, unknown>): boolean {
  if (schema.type === 'object') {
    if (typeof data !== 'object' || data === null) return false;

    const obj = data as Record<string, unknown>;
    const required = (schema.required as string[]) || [];

    for (const field of required) {
      if (!(field in obj)) return false;
    }
    return true;
  }

  if (schema.type === 'array') {
    if (!Array.isArray(data)) return false;

    const itemSchema = schema.items as Record<string, unknown>;
    return data.every((item) => validateSchema(item, itemSchema));
  }

  if (schema.type === 'string') {
    return typeof data === 'string';
  }

  return true;
}

describe('API Contract Tests', () => {
  let authToken: string;

  beforeAll(async () => {
    // 認証トークンを取得
    const loginRes = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: process.env.TEST_USER_EMAIL || 'test@example.com',
        password: process.env.TEST_USER_PASSWORD || 'password',
      }),
    });

    if (loginRes.ok) {
      const data = await loginRes.json();
      authToken = data.token;
    }
  });

  describe('GET /api/users', () => {
    it('レスポンスが仕様に準拠している', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        headers: {
          Authorization: `Bearer ${authToken}`,
        },
      });

      expect(res.status).toBe(200);

      const data = await res.json();
      const schema = apiSpec['/api/users'].get.responses[200].schema;

      expect(validateSchema(data, schema)).toBe(true);
    });

    it('Content-Typeがapplication/jsonである', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        headers: {
          Authorization: `Bearer ${authToken}`,
        },
      });

      expect(res.headers.get('content-type')).toContain('application/json');
    });
  });

  describe('POST /api/users', () => {
    it('正常なリクエストで201を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authToken}`,
        },
        body: JSON.stringify({
          email: `test-${Date.now()}@example.com`,
          name: 'Test User',
        }),
      });

      expect(res.status).toBe(201);

      const data = await res.json();
      const schema = apiSpec['/api/users'].post.responses[201].schema;

      expect(validateSchema(data, schema)).toBe(true);
    });

    it('必須フィールド欠落で400を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authToken}`,
        },
        body: JSON.stringify({
          // emailが欠落
          name: 'Test User',
        }),
      });

      expect(res.status).toBe(400);

      const data = await res.json();
      const schema = apiSpec['/api/users'].post.responses[400].schema;

      expect(validateSchema(data, schema)).toBe(true);
    });
  });

  describe('GET /api/users/{id}', () => {
    it('存在するユーザーで200を返す', async () => {
      // まずユーザーを作成
      const createRes = await fetch(`${BASE_URL}/api/users`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authToken}`,
        },
        body: JSON.stringify({
          email: `test-${Date.now()}@example.com`,
          name: 'Test User',
        }),
      });

      const created = await createRes.json();

      // 作成したユーザーを取得
      const res = await fetch(`${BASE_URL}/api/users/${created.id}`, {
        headers: {
          Authorization: `Bearer ${authToken}`,
        },
      });

      expect(res.status).toBe(200);

      const data = await res.json();
      const schema = apiSpec['/api/users/{id}'].get.responses[200].schema;

      expect(validateSchema(data, schema)).toBe(true);
    });

    it('存在しないユーザーで404を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users/00000000-0000-0000-0000-000000000000`, {
        headers: {
          Authorization: `Bearer ${authToken}`,
        },
      });

      expect(res.status).toBe(404);

      const data = await res.json();
      const schema = apiSpec['/api/users/{id}'].get.responses[404].schema;

      expect(validateSchema(data, schema)).toBe(true);
    });
  });

  describe('HTTPメソッド検証', () => {
    it('未対応メソッドで405を返す', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${authToken}`,
        },
      });

      expect(res.status).toBe(405);
    });
  });

  describe('バージョニング', () => {
    it('APIバージョンヘッダーが含まれる（任意）', async () => {
      const res = await fetch(`${BASE_URL}/api/users`, {
        headers: {
          Authorization: `Bearer ${authToken}`,
        },
      });

      // X-API-Versionヘッダーがあれば検証
      const apiVersion = res.headers.get('x-api-version');
      if (apiVersion) {
        expect(apiVersion).toMatch(/^\d+\.\d+(\.\d+)?$/);
      }
    });
  });
});
