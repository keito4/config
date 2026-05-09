// Vitest config テンプレート
//
// 使い方:
//   1. プロジェクトルートに `vitest.config.ts` としてコピー
//   2. 必要な依存をインストール:
//      npm install -D vitest @vitest/coverage-v8 jsdom
//      npm install -D @vitejs/plugin-react   # React 使用時
//   3. tests/setup.ts を作成 (testing-library/jest-dom 等)
//   4. package.json scripts に追加:
//      "test": "vitest run"
//      "test:watch": "vitest"
//      "test:coverage": "vitest run --coverage"
//
// プロジェクト固有のカスタマイズが必要な箇所はコメントで明記している。
import { defineConfig } from 'vitest/config';
import path from 'node:path';

// React プロジェクトの場合は以下を有効化:
// import react from '@vitejs/plugin-react';

export default defineConfig({
  // plugins: [react()],
  test: {
    // jsdom: ブラウザ DOM シミュレーション (React/UI テストで使用)
    // node: API/サーバサイドのみのプロジェクトでは 'node' に変更
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
    include: ['{src,tests,lib}/**/*.{test,spec}.{ts,tsx,js,jsx}'],
    exclude: ['node_modules/**', '.next/**', 'dist/**', 'tests/e2e/**', 'tests/regression/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      include: ['src/**/*.{ts,tsx}', 'lib/**/*.ts'],
      exclude: [
        '**/*.d.ts',
        '**/*.test.{ts,tsx}',
        '**/*.spec.{ts,tsx}',
        '**/types.ts',
        '**/types/**',
        '**/__tests__/**',
        '**/__mocks__/**',
      ],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70,
      },
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
