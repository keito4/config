/**
 * API Route Test Example
 *
 * このファイルは Next.js API ルートのテスト例です。
 * app/api/example/__tests__/route.test.ts として配置してください。
 */

import { GET, POST } from '../route';

// テスト用のモックリクエスト作成ヘルパー
function createMockRequest(method: string, body?: Record<string, unknown>, headers?: Record<string, string>): Request {
  const url = 'http://localhost:3000/api/example';

  return new Request(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
}

describe('/api/example', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET', () => {
    it('should return 200 with data', async () => {
      const request = createMockRequest('GET');
      const response = await GET(request);

      expect(response.status).toBe(200);

      const data = await response.json();
      expect(data).toHaveProperty('message');
    });

    it('should handle errors gracefully', async () => {
      // エラーケースのテスト
      const request = createMockRequest('GET', undefined, {
        'X-Force-Error': 'true',
      });

      const response = await GET(request);

      expect(response.status).toBe(500);
    });
  });

  describe('POST', () => {
    it('should create a resource and return 201', async () => {
      const request = createMockRequest('POST', {
        name: 'Test Item',
        value: 42,
      });

      const response = await POST(request);

      expect(response.status).toBe(201);

      const data = await response.json();
      expect(data).toMatchObject({
        name: 'Test Item',
        value: 42,
      });
    });

    it('should return 400 for invalid input', async () => {
      const request = createMockRequest('POST', {
        // 必須フィールドが欠けている
        value: 42,
      });

      const response = await POST(request);

      expect(response.status).toBe(400);
    });
  });
});
