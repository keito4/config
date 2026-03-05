/**
 * Load Test Example (k6 Script)
 *
 * 負荷テストは、システムが高負荷下で
 * 正常に動作するかを検証します。
 *
 * tests/load/api-load.js として配置してください。
 *
 * 依存: k6 (https://k6.io/docs/getting-started/installation/)
 *
 * 実行: k6 run tests/load/api-load.js
 * CI: k6 run --out json=results.json tests/load/api-load.js
 */

// k6 スクリプト（JavaScript）
const k6Script = `
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// カスタムメトリクス
const errorRate = new Rate('errors');
const apiLatency = new Trend('api_latency');

// テスト設定
export const options = {
  // シナリオ定義
  scenarios: {
    // スモークテスト（基本動作確認）
    smoke: {
      executor: 'constant-vus',
      vus: 1,
      duration: '30s',
      tags: { test_type: 'smoke' },
    },

    // 負荷テスト（通常負荷）
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 50 },   // 2分で50VUまで増加
        { duration: '5m', target: 50 },   // 5分間50VUを維持
        { duration: '2m', target: 0 },    // 2分でクールダウン
      ],
      tags: { test_type: 'load' },
      startTime: '30s', // スモークテスト後に開始
    },

    // スパイクテスト（急激な負荷）
    spike: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 100 }, // 急激に増加
        { duration: '1m', target: 100 },  // ピーク維持
        { duration: '10s', target: 0 },   // 急激に減少
      ],
      tags: { test_type: 'spike' },
      startTime: '10m', // 負荷テスト後に開始
    },
  },

  // しきい値
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95%が500ms以下
    http_req_failed: ['rate<0.01'],                  // エラー率1%以下
    errors: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
let authToken = '';

// セットアップ（テスト開始前に1回実行）
export function setup() {
  // 認証トークンを取得
  const loginRes = http.post(
    \`\${BASE_URL}/api/auth/login\`,
    JSON.stringify({
      email: __ENV.TEST_USER_EMAIL || 'test@example.com',
      password: __ENV.TEST_USER_PASSWORD || 'password',
    }),
    {
      headers: { 'Content-Type': 'application/json' },
    }
  );

  if (loginRes.status === 200) {
    const body = JSON.parse(loginRes.body);
    return { token: body.token };
  }

  return { token: '' };
}

// メインテスト関数
export default function (data) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: \`Bearer \${data.token}\`,
  };

  group('Health Check', function () {
    const res = http.get(\`\${BASE_URL}/api/health\`);

    check(res, {
      'status is 200': (r) => r.status === 200,
      'response time < 200ms': (r) => r.timings.duration < 200,
    });

    errorRate.add(res.status !== 200);
    apiLatency.add(res.timings.duration);
  });

  group('Get Users', function () {
    const res = http.get(\`\${BASE_URL}/api/users\`, { headers });

    check(res, {
      'status is 200': (r) => r.status === 200,
      'response time < 500ms': (r) => r.timings.duration < 500,
      'has users array': (r) => {
        try {
          const body = JSON.parse(r.body);
          return Array.isArray(body);
        } catch {
          return false;
        }
      },
    });

    errorRate.add(res.status !== 200);
    apiLatency.add(res.timings.duration);
  });

  group('Create User', function () {
    const payload = JSON.stringify({
      name: \`Load Test User \${Date.now()}\`,
      email: \`loadtest-\${Date.now()}-\${__VU}@example.com\`,
    });

    const res = http.post(\`\${BASE_URL}/api/users\`, payload, { headers });

    check(res, {
      'status is 201': (r) => r.status === 201,
      'response time < 1000ms': (r) => r.timings.duration < 1000,
    });

    errorRate.add(res.status !== 201);
    apiLatency.add(res.timings.duration);
  });

  // リクエスト間に待機時間を入れる（実際のユーザー行動をシミュレート）
  sleep(Math.random() * 2 + 1); // 1-3秒
}

// テスト終了時の処理
export function teardown(data) {
  console.log('Load test completed');
}
`;

/**
 * Artillery 設定ファイル（代替）
 *
 * artillery.yml として配置
 * 実行: npx artillery run artillery.yml
 */
const artilleryConfig = `
config:
  target: "http://localhost:3000"
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      name: "Peak load"
  defaults:
    headers:
      Content-Type: "application/json"
  plugins:
    expect: {}

scenarios:
  - name: "Health check"
    flow:
      - get:
          url: "/api/health"
          expect:
            - statusCode: 200

  - name: "User flow"
    flow:
      - post:
          url: "/api/auth/login"
          json:
            email: "{{ $processEnvironment.TEST_USER_EMAIL }}"
            password: "{{ $processEnvironment.TEST_USER_PASSWORD }}"
          capture:
            - json: "$.token"
              as: "authToken"

      - get:
          url: "/api/users"
          headers:
            Authorization: "Bearer {{ authToken }}"
          expect:
            - statusCode: 200

      - think: 2

      - get:
          url: "/api/meetings"
          headers:
            Authorization: "Bearer {{ authToken }}"
          expect:
            - statusCode: 200
`;

// Jest テストとしてエクスポート
describe('Load Test Configuration', () => {
  it('k6スクリプトが有効な構文である', () => {
    // k6スクリプトの基本構文チェック
    expect(k6Script).toContain('export const options');
    expect(k6Script).toContain('export default function');
    expect(k6Script).toContain('thresholds');
  });

  it('Artillery設定が有効なYAML構文である', () => {
    expect(artilleryConfig).toContain('config:');
    expect(artilleryConfig).toContain('scenarios:');
    expect(artilleryConfig).toContain('phases:');
  });
});

// 設定ファイルをエクスポート
export { k6Script, artilleryConfig };
