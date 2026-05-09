// commitlint テンプレート (Conventional Commits)
//
// 使い方:
//   1. プロジェクトルートに `commitlint.config.js` としてコピー
//   2. 必要な依存をインストール:
//      npm install -D @commitlint/cli @commitlint/config-conventional
//   3. .husky/commit-msg に以下を追加 (setup-husky 実行で自動設定):
//      npx --no-install commitlint --edit "$1"
//
// 許可される type:
//   feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
//
// scope は project 固有。CLAUDE.md / AGENTS.md の git-conventions を参照。
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Subject 末尾のピリオド禁止 (デフォルト: error)
    'subject-full-stop': [2, 'never', '.'],
    // 本文の最大行長 (日本語コミットの場合は緩和推奨)
    'body-max-line-length': [1, 'always', 100],
    // フッターの最大行長
    'footer-max-line-length': [1, 'always', 100],
  },
};
