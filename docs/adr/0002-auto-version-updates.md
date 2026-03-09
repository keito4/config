# ADR 0002: Automated Version Updates Strategy

## Status

Accepted

## Context

開発ツールのバージョンを常に最新に保つことで、セキュリティパッチや新機能を迅速に適用したい。
しかし、自動更新による破壊的変更のリスクも考慮する必要がある。

## Decision

以下のワークフローで自動更新を管理する：

### ワークフロー一覧

| ワークフロー                | 対象                                      | 頻度 | 動作                            |
| --------------------------- | ----------------------------------------- | ---- | ------------------------------- |
| `update-claude-code.yml`    | Claude Code                               | 毎日 | npm registry から最新版を取得   |
| `update-dev-tools.yml`      | GH CLI, Doppler, 1Password, Node.js, pnpm | 毎日 | GitHub/npm API から最新版を取得 |
| `update-libraries.yml`      | npm packages                              | 毎週 | `npm run update:libs` を実行    |
| `update-claude-plugins.yml` | Claude plugins                            | 毎週 | プラグインの更新をチェック      |
| Dependabot                  | npm dev deps, GitHub Actions              | 毎週 | 標準の Dependabot 機能          |

### バージョン取得元

| ツール        | 取得元                                       |
| ------------- | -------------------------------------------- |
| Claude Code   | `npm view @anthropic-ai/claude-code version` |
| GitHub CLI    | GitHub Releases API                          |
| Doppler CLI   | GitHub Releases API                          |
| 1Password CLI | AgileBits API                                |
| Node.js       | nodejs.org API (LTS)                         |
| pnpm          | npm registry                                 |

## Consequences

### Positive

- セキュリティパッチが迅速に適用される
- 手動更新の手間が削減される
- 更新履歴がPRとして記録される

### Negative

- 破壊的変更が自動で提案される可能性
- CI コストの増加

### Mitigation

- PRはマージ前に CI でテスト
- 重要な更新は手動レビューを推奨
