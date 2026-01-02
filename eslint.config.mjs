import js from '@eslint/js';
import globals from 'globals';
import eslintConfigPrettier from 'eslint-config-prettier';

export default [
  {
    ignores: ['node_modules/', 'dist/', 'coverage/', '*.min.js'],
  },
  js.configs.recommended,
  eslintConfigPrettier,
  {
    files: ['**/*.{js,jsx}'],
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
      // Complexity rules (Phase 1: warnings to prevent new technical debt)
      // See eslint/README.md for detailed documentation
      complexity: ['warn', { max: 15 }],
      'max-lines-per-function': [
        'warn',
        {
          max: 100,
          skipBlankLines: true,
          skipComments: true,
        },
      ],
      'max-lines': [
        'warn',
        {
          max: 500,
          skipBlankLines: true,
          skipComments: true,
        },
      ],
      'max-depth': ['warn', 4],
      'max-params': ['warn', 5],
      'max-nested-callbacks': ['warn', 3],
    },
  },
  // Relaxed rules for test files
  {
    files: ['**/*.test.js', '**/*.spec.js', '**/test/**/*.js'],
    rules: {
      'max-lines-per-function': 'off',
      'max-nested-callbacks': ['warn', 5],
    },
  },
];
