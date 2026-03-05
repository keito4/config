/**
 * Jest Configuration for Regression Tests
 *
 * リグレッションテスト用の設定。
 * API エンドポイントへの実際のリクエストを行うため、
 * タイムアウトを長めに設定し、Node.js 環境で実行する。
 */

/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/regression/**/*.test.ts'],
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        tsconfig: 'tsconfig.json',
      },
    ],
  },
  // API呼び出しを含むため長めのタイムアウト
  testTimeout: 30000,
  // 並列実行数を制限（サーバー負荷軽減）
  maxWorkers: 2,
  // テスト失敗時に即座に停止しない
  bail: false,
  // 詳細なエラー表示
  verbose: true,
};
