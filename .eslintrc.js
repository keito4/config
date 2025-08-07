module.exports = {
  extends: ['eslint:recommended', 'prettier'],
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    // プロジェクト固有のルールを追加
    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
      },
    ],
  },
  ignorePatterns: ['node_modules/', 'dist/', 'build/', 'coverage/', '*.config.js', '.devcontainer/'],
};
