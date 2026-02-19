# セットアップガイド

プロジェクト種別ごとのセットアップ手順を提供する。
[CLAUDE.md](../../CLAUDE.md) の品質基準に基づく。

## 共通品質ゲート（全プロジェクト必須）

| 品質ゲート   | 基準                                                |
| ------------ | --------------------------------------------------- |
| Unit テスト  | 全プロジェクトで導入必須                            |
| カバレッジ   | 70%+ (lines / branches / functions / statements)    |
| Lint         | Error=Fail、`--max-warnings 0`                      |
| Format 検証  | CI で `format:check` を実行、Auto-fix 無効時は Fail |
| CI/CD        | Lint → Test → Build → SCA → Deploy                  |
| Git hooks    | husky + commitlint + lint-staged（または lefthook） |
| CLAUDE.md    | 技術スタック・テスト戦略・デプロイ先を記載          |
| SAST         | Critical 検知で Fail                                |
| DevContainer | `ghcr.io/keito4/config-base:latest` ベース          |

## プロジェクト別ガイド

| ガイド                                               | 対応種別              |
| ---------------------------------------------------- | --------------------- |
| [spa-react-vite.md](./spa-react-vite.md)             | SPA (React + Vite)    |
| [npm-library-cli.md](./npm-library-cli.md)           | npm ライブラリ (CLI)  |
| [web-app-nextjs.md](./web-app-nextjs.md)             | Web アプリ (Next.js)  |
| [mobile-flutter.md](./mobile-flutter.md)             | モバイル (Flutter)    |
| [mobile-android.md](./mobile-android.md)             | モバイル (Android)    |
| [desktop-extension-ts.md](./desktop-extension-ts.md) | デスクトップ拡張 (TS) |

---

## 共通パターン（プロジェクト非依存）

以下はすべてのプロジェクトに適用すべき共通パターン。

### husky + commitlint + lint-staged

3 フックパターンを標準とする。

```bash
npm install -D husky @commitlint/cli @commitlint/config-conventional lint-staged
npx husky init
```

**commit-msg** (`commitlint`):

```bash
echo 'npx commitlint --edit "$1"' > .husky/commit-msg
```

**pre-commit** (`lint-staged`):

```bash
echo 'npx lint-staged' > .husky/pre-commit
```

**pre-push** (typecheck + lint + test):

```bash
echo 'npm run typecheck && npm run lint && npm run test' > .husky/pre-push
```

> Node.js 非依存のプロジェクト（Flutter / Android）は [lefthook](https://github.com/evilmartians/lefthook) を使用する。

**commitlint.config.js**:

```js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'body-max-line-length': [2, 'always', 120],
    // 日本語コミットメッセージを許可
    'subject-case': [0],
  },
};
```

### CI/CD パイプライン

#### 最小構成

```
変更検出 → Lint + Format → Test (coverage) → Build → Quality Gate
```

#### paths-filter による条件実行

不要なジョブの実行を回避し CI を高速化する。

```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      code: ${{ steps.filter.outputs.code }}
      scripts: ${{ steps.filter.outputs.scripts }}
    steps:
      - uses: actions/checkout@v6
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            code:
              - '**.ts'
              - '**.tsx'
              - 'src/**'
            scripts:
              - '**.sh'
              - 'script/**'
```

#### concurrency（重複実行防止）

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

#### Quality Gate 集約ジョブ

Branch Protection の Required Status Check に **このジョブだけ** を指定する。個別ジョブの追加・削除時にルール変更が不要になる。

```yaml
quality-gate:
  runs-on: ubuntu-latest
  needs: [lint, test, build]
  if: always()
  steps:
    - name: Verify all checks passed
      run: |
        for result in "$LINT" "$TEST" "$BUILD"; do
          if [[ "$result" != "success" && "$result" != "skipped" ]]; then
            echo "::error::Quality gate failed"
            exit 1
          fi
        done
      env:
        LINT: ${{ needs.lint.result }}
        TEST: ${{ needs.test.result }}
        BUILD: ${{ needs.build.result }}
```

#### PR サイズラベリング

PR の diff 行数・ファイル数に応じて `size/XS` 〜 `size/XL` ラベルを自動付与する。XL（1000 行超 or 30 ファイル超）は警告コメントを投稿する。

```yaml
pr-size-check:
  if: github.event_name == 'pull_request'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/github-script@v7
      with:
        script: |
          const { additions, deletions, changed_files } = context.payload.pull_request;
          const total = additions + deletions;
          const sizes = [
            { label: 'size/XS', maxLines: 50, maxFiles: 3 },
            { label: 'size/S', maxLines: 200, maxFiles: 10 },
            { label: 'size/M', maxLines: 500, maxFiles: 15 },
            { label: 'size/L', maxLines: 1000, maxFiles: 30 },
          ];
          let sizeLabel = 'size/XL';
          for (const s of sizes) {
            if (total <= s.maxLines && changed_files <= s.maxFiles) {
              sizeLabel = s.label;
              break;
            }
          }
          // ラベル付与（省略）
```

#### Slack 失敗通知

main ブランチの CI 失敗時に Slack へ通知する。

```yaml
notify-failure:
  needs: [quality-gate]
  if: failure() && github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  steps:
    - uses: slackapi/slack-github-action@v2
      with:
        channel-id: ${{ vars.SLACK_CI_CHANNEL_ID }}
        payload-template-file-path: '.github/slack-ci-failure.json'
      env:
        SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

#### actionlint（ワークフロー構文検証）

```yaml
actionlint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: reviewdog/action-actionlint@v1
      with:
        reporter: github-pr-review
        fail_on_error: true
```

### セキュリティワークフロー（security.yml）

4 ジョブ構成を標準とする。

| ジョブ              | 内容                           | トリガー  |
| ------------------- | ------------------------------ | --------- |
| `gitleaks`          | シークレット検出               | push + PR |
| `dependency-review` | 依存パッケージの脆弱性レビュー | PR のみ   |
| `npm-audit`         | npm 脆弱性スキャン             | push + PR |
| `license-check`     | 禁止ライセンス検出             | push + PR |

**ポイント**:

- `dependency-review`: `fail-on-severity: critical`、`deny-licenses: GPL-3.0, AGPL-3.0`
- `license-check`: `--failOn "GPL-3.0;AGPL-3.0;GPL-2.0;AGPL-1.0"`
- `schedule: cron: '0 5 * * *'` で日次実行を追加

### Claude Code Hooks

Claude Code の操作前後に品質チェックを自動実行する仕組み。`.claude/hooks/` にスクリプトを配置し、`.claude/settings.json` で設定する。

#### 推奨 Hooks 構成

| Hook                       | タイミング  | 用途                                       |
| -------------------------- | ----------- | ------------------------------------------ |
| `block_git_no_verify.py`   | PreToolUse  | `--no-verify` / `HUSKY=0` の使用をブロック |
| `pre_git_quality_gates.py` | PreToolUse  | commit/push 前に品質チェック一括実行       |
| `post_git_push_ci.py`      | PostToolUse | push 後に CI 状態を自動監視                |

#### settings.json の設定例

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [".claude/hooks/block_git_no_verify.py", ".claude/hooks/pre_git_quality_gates.py"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [".claude/hooks/post_git_push_ci.py"]
      }
    ]
  }
}
```

#### Quality Gates の実行内容

`pre_git_quality_gates.py` は `git commit` / `git push` を検出し、以下を順次実行する:

1. Format Check (`npm run format:check`)
2. Lint (`npm run lint`)
3. Test (`npm run test`)
4. ShellCheck (`npm run shellcheck`)
5. Security Credential Scan
6. Code Complexity Check

> ツールが未インストールの場合は自動スキップし、検出された問題のみブロックする。

### Claude Code ワークフロー

2 つのワークフローを標準で導入する。

| ワークフロー             | トリガー             | 用途                      |
| ------------------------ | -------------------- | ------------------------- |
| `claude.yml`             | `@claude` メンション | Issue/PR での AI アシスト |
| `claude-code-review.yml` | PR 作成・更新        | 自動コードレビュー        |

> config リポジトリのワークフローをテンプレートとして使用する。

### DevContainer

#### ベースイメージ

```json
{
  "image": "ghcr.io/keito4/config-base:latest"
}
```

> `:latest` タグで常に最新の安定版を使用する。`/config-base-sync-check` でバージョンを確認可能。

#### 共通 mounts

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,readonly",
    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind"
  ]
}
```

#### プロジェクト固有 Features の判断基準

ベースイメージに含まれるもの（git, node, pnpm, gh, jq-likes, supabase-cli）は **Features として追加しない**。プロジェクト固有のものだけ追加する:

| プロジェクト種別 | 追加 Features 例             |
| ---------------- | ---------------------------- |
| Next.js          | docker-in-docker, playwright |
| Flutter          | flutter, java(17)            |
| Android          | java(17) + Gradle            |
| Raycast 拡張     | docker-in-docker             |

> **Note**: `/setup-new-repo` コマンドはプロジェクトタイプを自動検出し、[project-presets.json](../../.devcontainer/templates/project-presets.json) の定義に基づいて適切な Features、Skills、Plugins を自動設定する。

### リリース管理（semantic-release）

Node.js プロジェクトは **semantic-release** を標準とする。

```json
{
  "branches": ["main"],
  "plugins": [
    ["@semantic-release/commit-analyzer", { "preset": "conventionalcommits" }],
    ["@semantic-release/release-notes-generator", { "preset": "conventionalcommits" }],
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    ["@semantic-release/git", { "assets": ["CHANGELOG.md", "package.json", "package-lock.json"] }]
  ]
}
```

> Flutter / Android は日付ベースバージョニング（`v{YYYY.MM.DD}-{short-sha}`）を使用する場合がある。

### ファイルサイズ制約

全プロジェクトに以下の制約を適用する:

| 制約                         | 閾値       | 検出方法                   |
| ---------------------------- | ---------- | -------------------------- |
| 1 ファイルの行数             | 500 行以下 | Code Complexity Check      |
| 関数の Cyclomatic Complexity | 10 以下    | ESLint `complexity` ルール |
| 認知的複雑度                 | 15 以下    | ESLint `max-depth` ルール  |
| ネストの深さ                 | 4 以下     | ESLint `max-depth` ルール  |

**ESLint ルール例**:

```json
{
  "complexity": ["error", 10],
  "max-lines": ["warn", { "max": 500, "skipBlankLines": true, "skipComments": true }],
  "max-depth": ["error", 4]
}
```

> Biome を使用するプロジェクトでは `noExcessiveCognitiveComplexity` ルールで同等の制約を実現する。

### ライブラリ自動更新

依存パッケージを定期的に最新化する仕組み。

```yaml
name: Update Libraries
on:
  schedule:
    - cron: '0 0 * * 1' # 毎週月曜
  workflow_dispatch:
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: npm update
      - uses: peter-evans/create-pull-request@v7
        with:
          title: 'chore(deps): update dependencies'
          branch: chore/update-dependencies
```

---

## 共通コマンド

| コマンド                    | 用途                                            |
| --------------------------- | ----------------------------------------------- |
| `/setup-husky`              | husky + lint-staged + commitlint の最小構成導入 |
| `/setup-ci`                 | CI/CD ワークフローの雛形作成                    |
| `/setup-new-repo`           | 新規リポジトリの初期セットアップ一式            |
| `/config-base-sync-update`  | DevContainer ベースイメージを最新版に更新       |
| `/config-base-sync-check`   | 現在のベースイメージバージョンを確認            |
| `/security-credential-scan` | 認証情報の漏洩スキャン                          |
| `/code-complexity-check`    | コード複雑度チェック                            |
| `/dependency-health-check`  | 依存パッケージの健全性チェック                  |

---

## 関連ドキュメント

| ドキュメント                                                               | 説明                                              |
| -------------------------------------------------------------------------- | ------------------------------------------------- |
| [project-presets.json](../../.devcontainer/templates/project-presets.json) | プロジェクトタイプ別の推奨設定マスター            |
| [ツールカタログ](../tool-catalog.md)                                       | 環境×ツールのマトリクス（何がどこで使えるか一覧） |
| [config-base イメージ](../using-config-base-image.md)                      | DevContainer ベースイメージの詳細                 |
| [MCP サーバーガイド](../mcp-servers-guide.md)                              | Linear, Playwright, Supabase 等の MCP 連携        |
| [Sentry セットアップガイド](../sentry-setup-guide.md)                      | Next.js 14+ 向けの Sentry 設定                    |
