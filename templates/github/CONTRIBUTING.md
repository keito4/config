# Contributing Guide

このプロジェクトへの貢献に興味を持っていただきありがとうございます。

## 開発の始め方

1. リポジトリをフォーク
2. ブランチを作成: `git checkout -b feat/<issue#>-slug`
3. 変更をコミット（[Conventional Commits](#commit-規約) に従う）
4. PR を作成

## Commit 規約

[Conventional Commits](https://www.conventionalcommits.org/ja/) に従います:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type

| Type       | 用途                         |
| ---------- | ---------------------------- |
| `feat`     | 新機能                       |
| `fix`      | バグ修正                     |
| `docs`     | ドキュメントのみの変更       |
| `style`    | コードの意味に影響しない変更 |
| `refactor` | リファクタリング             |
| `perf`     | パフォーマンス改善           |
| `test`     | テストの追加・修正           |
| `chore`    | ビルドプロセスやツールの変更 |
| `ci`       | CI/CD の変更                 |
| `deps`     | 依存関係の更新               |

## Pull Request ガイドライン

- Diff は **400行以下**、ファイル数は **25以下**
- 関連する Issue をリンク
- テストを追加・更新
- CI が緑であることを確認
- 最低1名のレビュー承認を取得

## コードスタイル

- フォーマッター・リンターの設定に従う
- `pre-commit` フックが自動的にチェックを実行

## Issue の報告

- バグ報告: Issue テンプレート「Bug Report」を使用
- 機能提案: Issue テンプレート「Feature Request」を使用
