const { execSync } = require('child_process');

const releaseTypeAllowList = new Set(['feat', 'fix', 'perf', 'revert', 'docs']);
const releaseSensitivePatterns = [
  /^package\.json$/,
  /^package-lock\.json$/,
  /^npm\/global\.json$/,
  /^\.devcontainer\/Dockerfile$/,
  /^\.codex\//,
];

/**
 * @returns {string[]} List of staged file paths
 */
const getStagedFiles = () => {
  try {
    return execSync('git diff --cached --name-only', { encoding: 'utf8' }).split('\n').filter(Boolean);
  } catch {
    return [];
  }
};

/**
 * @param {{ type: string | null | undefined }} parsed - Parsed commit message object
 * @returns {[true] | [false, string]} Validation result: [true] on pass, [false, message] on fail
 */
const releaseTypeRule = (parsed) => {
  const files = getStagedFiles();
  const touched = files.filter((file) => releaseSensitivePatterns.some((pattern) => pattern.test(file)));

  if (!touched.length) {
    return [true];
  }

  const isReleaseType = releaseTypeAllowList.has(parsed.type || '');
  if (isReleaseType) {
    return [true, `Changes in ${touched.join(', ')} will trigger a semantic-release.`];
  }
  return [
    false,
    `Changes in ${touched.join(', ')} require a release-triggering type (feat|fix|perf|revert|docs) to keep semantic-release automated.`,
  ];
};

module.exports = {
  extends: ['@commitlint/config-conventional'],
  plugins: [
    {
      rules: {
        'codex-release-type': (parsed) => releaseTypeRule(parsed),
      },
    },
  ],
  rules: {
    'subject-case': [0], // 日本語対応のため無効化
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'scope-empty': [0],
    'codex-release-type': [2, 'always'],
  },
};
