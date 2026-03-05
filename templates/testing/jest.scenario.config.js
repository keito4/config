/**
 * Jest Configuration for Scenario Tests
 *
 * シナリオテスト（ビジネスフロー）用の設定。
 * 複数ステップのフローを順番に実行するため、
 * 直列実行（runInBand）を使用する。
 */

/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/scenario/**/*.test.ts', '**/tests/integration/scenario*.test.ts'],
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        tsconfig: 'tsconfig.json',
      },
    ],
  },
  // シナリオテストは長時間実行される可能性がある
  testTimeout: 60000,
  // シナリオテストは順番に実行する必要がある
  maxWorkers: 1,
  // 詳細なログ出力
  verbose: true,
  // テスト失敗時に即座に停止（シナリオの途中で失敗した場合、後続は意味がない）
  bail: true,
};
