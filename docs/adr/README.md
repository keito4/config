# Architecture Decision Records (ADR)

このディレクトリには、プロジェクトの重要なアーキテクチャ決定を記録しています。

## ADR 一覧

| ADR                                                             | タイトル                                                     | Status             |
| --------------------------------------------------------------- | ------------------------------------------------------------ | ------------------ |
| [0001](0001-devcontainer-base-image.md)                         | DevContainer Base Image Architecture                         | Accepted           |
| [0002](0002-auto-version-updates.md)                            | Automated Version Updates Strategy                           | Superseded by 0006 |
| [0003](0003-remove-rust-from-base-image.md)                     | Remove Rust from base image                                  | Accepted           |
| [0004](0004-dependabot-minor-auto-merge.md)                     | Dependabot minor auto-merge                                  | Accepted           |
| [0005](0005-npm-legacy-peer-deps-for-typescript6.md)            | npm legacy-peer-deps for TypeScript 6                        | Accepted           |
| [0006](0006-consolidate-version-updates.md)                     | バージョン更新の Dependabot 一本化                           | Accepted           |
| [0007](0007-separate-claude-pr-creation-step.md)                | Separate Claude Pull Request Creation From Claude Bash Tools | Accepted           |
| [0008](0008-documentation-single-source-of-truth.md)            | Documentation Single Source Of Truth                         | Accepted           |
| [0009](0009-workflow-template-synchronization.md)               | Workflow Template Synchronization                            | Accepted           |
| [0010](0010-ci-workflow-consolidation.md)                       | CI workflow consolidation                                    | Accepted           |
| [0011](0011-hook-and-script-dry-boundaries.md)                  | Hook and Script DRY Boundaries                               | Accepted           |
| [0012](0012-environment-source-of-truth.md)                     | Environment Source of Truth                                  | Accepted           |
| [0014](0014-manage-cmux-karabiner-with-home-manager.md)         | Manage cmux and Karabiner Configuration with Home Manager    | Superseded by 0016 |
| [0015](0015-manage-portable-user-dotfiles-with-home-manager.md) | Manage Portable User Dotfiles with Home Manager              | Accepted           |
| [0016](0016-use-kanary-for-keyboard-remapping.md)               | Use Kanary for Keyboard Remapping                            | Accepted           |
| [0017](0017-distribute-user-memory-via-config-repo.md)          | ユーザーメモリーを config リポジトリ経由で配布               | Accepted           |

## ADR テンプレート

新しい ADR を作成する場合は、以下のテンプレートを使用してください：

```markdown
# ADR XXXX: タイトル

## Status

Proposed | Accepted | Deprecated | Superseded

## Context

決定が必要になった背景や問題を説明。

## Decision

採用した決定の内容。

## Consequences

### Positive

- 良い影響

### Negative

- 悪い影響

### Mitigation

- 悪い影響への対策
```

## 参考

- [ADR GitHub Organization](https://adr.github.io/)
- [Michael Nygard's ADR Template](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/templates/decision-record-template-by-michael-nygard/index.md)
