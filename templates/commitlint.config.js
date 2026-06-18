// Source: commitlint.config.js
// Keep this template aligned with the repository root commitlint configuration.
//
// commitlint テンプレート (Conventional Commits)
//
// 使い方:
//   1. プロジェクトルートに `commitlint.config.js` としてコピー
//   2. 必要な依存をインストール:
//      npm install -D @commitlint/cli @commitlint/config-conventional
//   3. .husky/commit-msg に以下を追加 (setup-husky 実行で自動設定):
//      npx --no-install commitlint --edit "$1"
//
const { execSync } = require('child_process');

const releaseTypeAllowList = new Set(['feat', 'fix', 'perf', 'revert', 'docs']);
const releaseSensitivePatterns = [
  /^package\.json$/,
  /^package-lock\.json$/,
  /^npm\/global\.json$/,
  /^\.devcontainer\/Dockerfile$/,
  /^\.codex\//,
];

const getStagedFiles = () => {
  try {
    return execSync('git diff --cached --name-only', { encoding: 'utf8' }).split('\n').filter(Boolean);
  } catch {
    return [];
  }
};

const releaseTypeRule = (parsed) => {
  const files = getStagedFiles();
  const touched = files.filter((file) => releaseSensitivePatterns.some((pattern) => pattern.test(file)));

  if (!touched.length) {
    return [true];
  }

  const isReleaseType = releaseTypeAllowList.has(parsed.type || '');
  return [
    isReleaseType,
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
    'subject-case': [0],
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'scope-empty': [0],
    'codex-release-type': [2, 'always'],
  },
};
