/**
 * Edge Functions Test Example
 *
 * Edge Functionsテストは、Supabase Edge Functions
 * (Deno) の動作を検証するテストです。
 *
 * supabase/functions/hello-world/index.test.ts として配置
 *
 * 実行: cd supabase/functions && deno test --allow-all
 */

// Deno 用のテストコード
const denoTestCode = `
// supabase/functions/hello-world/index.test.ts

import { assertEquals, assertExists } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "http://localhost:54321";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const FUNCTION_URL = \`\${SUPABASE_URL}/functions/v1/hello-world\`;

Deno.test("hello-world function returns greeting", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": \`Bearer \${SUPABASE_ANON_KEY}\`,
    },
    body: JSON.stringify({ name: "Test" }),
  });

  assertEquals(response.status, 200);

  const data = await response.json();
  assertEquals(data.message, "Hello, Test!");
});

Deno.test("hello-world function handles missing name", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": \`Bearer \${SUPABASE_ANON_KEY}\`,
    },
    body: JSON.stringify({}),
  });

  assertEquals(response.status, 200);

  const data = await response.json();
  assertEquals(data.message, "Hello, World!");
});

Deno.test("hello-world function requires authentication", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      // Authorization ヘッダーなし
    },
    body: JSON.stringify({ name: "Test" }),
  });

  // 認証エラー
  assertEquals(response.status, 401);
});

Deno.test("hello-world function handles invalid JSON", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": \`Bearer \${SUPABASE_ANON_KEY}\`,
    },
    body: "invalid json",
  });

  // Bad Request
  assertEquals(response.status, 400);
});
`;

// Jest テスト（Edge Functions の HTTP 呼び出し）
const BASE_URL = process.env.SUPABASE_URL || 'http://localhost:54321';
const ANON_KEY = process.env.SUPABASE_ANON_KEY || '';

describe('Edge Functions Tests (via HTTP)', () => {
  describe('hello-world function', () => {
    const functionUrl = `${BASE_URL}/functions/v1/hello-world`;

    it('正常なリクエストで挨拶を返す', async () => {
      const res = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${ANON_KEY}`,
        },
        body: JSON.stringify({ name: 'Jest' }),
      });

      if (res.status === 404) {
        // Edge Function がデプロイされていない場合はスキップ
        console.log('Edge Function not deployed, skipping test');
        return;
      }

      expect(res.status).toBe(200);

      const data = await res.json();
      expect(data.message).toBe('Hello, Jest!');
    });

    it('認証なしで401を返す', async () => {
      const res = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: 'Test' }),
      });

      if (res.status === 404) {
        console.log('Edge Function not deployed, skipping test');
        return;
      }

      expect(res.status).toBe(401);
    });
  });

  describe('process-webhook function', () => {
    const functionUrl = `${BASE_URL}/functions/v1/process-webhook`;

    it('Webhook署名を検証する', async () => {
      const payload = { event: 'test', data: { id: 1 } };
      const signature = 'invalid-signature';

      const res = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Signature': signature,
        },
        body: JSON.stringify(payload),
      });

      if (res.status === 404) {
        console.log('Edge Function not deployed, skipping test');
        return;
      }

      // 無効な署名で401
      expect(res.status).toBe(401);
    });
  });

  describe('Edge Function パフォーマンス', () => {
    it('レスポンス時間が許容範囲内', async () => {
      const functionUrl = `${BASE_URL}/functions/v1/hello-world`;

      const startTime = Date.now();

      const res = await fetch(functionUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${ANON_KEY}`,
        },
        body: JSON.stringify({ name: 'Performance' }),
      });

      const duration = Date.now() - startTime;

      if (res.status === 404) {
        console.log('Edge Function not deployed, skipping test');
        return;
      }

      // 500ms以内に応答
      expect(duration).toBeLessThan(500);
    });
  });

  describe('Edge Function CORS', () => {
    it('CORS ヘッダーが設定されている', async () => {
      const functionUrl = `${BASE_URL}/functions/v1/hello-world`;

      const res = await fetch(functionUrl, {
        method: 'OPTIONS',
        headers: {
          Origin: 'http://localhost:3000',
          'Access-Control-Request-Method': 'POST',
        },
      });

      if (res.status === 404) {
        console.log('Edge Function not deployed, skipping test');
        return;
      }

      const allowOrigin = res.headers.get('access-control-allow-origin');
      const allowMethods = res.headers.get('access-control-allow-methods');

      expect(allowOrigin).toBeTruthy();
      expect(allowMethods).toContain('POST');
    });
  });
});

// Deno テストコードをエクスポート（参照用）
export { denoTestCode };
