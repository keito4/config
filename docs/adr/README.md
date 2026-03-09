# Architecture Decision Records (ADR)

このディレクトリには、プロジェクトの重要なアーキテクチャ決定を記録しています。

## ADR 一覧

| ADR                                     | タイトル                             | Status   |
| --------------------------------------- | ------------------------------------ | -------- |
| [0001](0001-devcontainer-base-image.md) | DevContainer Base Image Architecture | Accepted |
| [0002](0002-auto-version-updates.md)    | Automated Version Updates Strategy   | Accepted |

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
