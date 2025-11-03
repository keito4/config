import js from '@eslint/js';
import prettier from 'eslint-config-prettier';
import globals from 'globals';

export default [
  // 無視パターン
  {
    ignores: ['node_modules/', 'dist/', 'coverage/', '*.min.js', 'test/bats-libs/'],
  },

  // 推奨ルール
  js.configs.recommended,

  // プロジェクト固有の設定
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    rules: {
      'no-console': 'off',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'prefer-const': 'error',
      'no-var': 'error',
      'object-shorthand': 'error',
      'prefer-arrow-callback': 'error',
      'prefer-template': 'error',
      'prefer-spread': 'error',
      'no-useless-return': 'error',
      'no-useless-concat': 'error',
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      curly: ['error', 'all'],
      'no-throw-literal': 'error',
      'prefer-promise-reject-errors': 'error',
    },
  },

  // テストコード用のオーバーライド
  {
    files: ['test/**/*.js'],
    rules: {
      'no-unused-vars': 'off',
    },
  },

  // Prettier 連携（競合するスタイル系ルールを無効化）
  prettier,
];
