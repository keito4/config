/**
 * Stryker Mutation Testing Configuration
 *
 * ミューテーションテストは、テストコード自体の品質を検証します。
 * ソースコードに意図的な変更（ミューテーション）を加え、
 * テストがそれを検出できるかを確認します。
 *
 * stryker.conf.js としてプロジェクトルートに配置してください。
 *
 * 依存パッケージ:
 * npm install -D @stryker-mutator/core @stryker-mutator/jest-runner @stryker-mutator/typescript-checker
 *
 * 実行: npx stryker run
 */

/** @type {import('@stryker-mutator/api/core').PartialStrykerOptions} */
const config = {
  // パッケージマネージャー
  packageManager: 'npm',

  // テストランナー
  testRunner: 'jest',
  jest: {
    configFile: 'jest.config.js',
  },

  // TypeScript チェッカー
  checkers: ['typescript'],
  tsconfigFile: 'tsconfig.json',

  // ミューテーション対象
  mutate: [
    'lib/**/*.ts',
    'hooks/**/*.ts',
    'app/**/*.ts',
    '!**/*.test.ts',
    '!**/*.spec.ts',
    '!**/__tests__/**',
    '!**/node_modules/**',
  ],

  // レポーター
  reporters: ['html', 'clear-text', 'progress'],
  htmlReporter: {
    fileName: 'reports/mutation/mutation.html',
  },

  // タイムアウト設定
  timeoutMS: 60000,
  timeoutFactor: 1.5,

  // 並列実行
  concurrency: 4,

  // カバレッジ分析（高速化のため）
  coverageAnalysis: 'perTest',

  // しきい値（ミューテーションスコア）
  thresholds: {
    high: 80,
    low: 60,
    break: 50, // 50%未満で失敗
  },

  // 無視するミューテーター
  ignorers: [],

  // ミューテーター設定
  mutator: {
    // 特定のパターンを除外
    excludedMutations: [
      'StringLiteral', // 文字列リテラルの変更は除外
    ],
  },

  // ダッシュボード（オプション）
  // dashboard: {
  //   project: 'github.com/your-org/your-repo',
  //   module: 'your-module',
  //   reportType: 'full',
  // },
};

module.exports = config;
