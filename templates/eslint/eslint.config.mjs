/**
 * ESLint flat config テンプレート (TypeScript / Next.js プロジェクト向け)
 *
 * 使い方:
 *   1. プロジェクトルートに `eslint.config.mjs` としてコピー
 *   2. 必要な依存をインストール:
 *      npm install -D eslint typescript-eslint
 *   3. (オプション) Next.js プロジェクトの場合:
 *      npm install -D eslint-config-next
 *      → 下記 Next.js セクションのコメントを外す
 *   4. (オプション) 複雑度ルールを有効化:
 *      → complexityRules import のコメントを外す
 *
 * 参考: keito4/config の eslint/complexity-rules.mjs を ./eslint/ に
 *      コピーして import すると複雑度ガードが有効になる
 */
import tseslint from 'typescript-eslint';
// import { complexityRules } from './eslint/complexity-rules.mjs';
// import nextCoreWebVitals from 'eslint-config-next/core-web-vitals';
// import nextTypescript from 'eslint-config-next/typescript';

export default [
  {
    ignores: [
      'node_modules/**',
      '.next/**',
      'dist/**',
      'build/**',
      'coverage/**',
      'public/**',
      '.vercel/**',
      '**/*.generated.*',
      '**/database.types.ts',
    ],
  },
  ...tseslint.configs.recommended,
  // ...nextCoreWebVitals,
  // ...nextTypescript,
  {
    files: ['**/*.{ts,tsx}'],
    rules: {
      // 警告は許容、未使用変数は _ 接頭辞で許可
      '@typescript-eslint/no-unused-vars': [
        'warn',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
      // 複雑度ルールを取り込む場合:
      // ...complexityRules,
    },
  },
];
