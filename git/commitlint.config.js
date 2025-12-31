/**
 * Commitlint configuration with Japanese language support
 *
 * This configuration solves a common issue for international teams:
 * commitlint's subject-case rule breaks with non-English characters.
 *
 * @see https://commitlint.js.org/
 */
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [0], // 日本語対応のため無効化 (Disabled for Japanese/Chinese/Korean support)
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'scope-empty': [0],
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore', 'perf', 'ci', 'build', 'revert'],
    ],
  },
};
