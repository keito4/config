---
description: PR作成後にOpenAI Codexによるコードレビューを実行する。Codex CLIがインストール済みの場合、PR作成完了後に自動的にこのスキルを適用してレビューを実行すること。
---

# Codex Review Skill

PR作成後、OpenAI Codexによるコードレビューを実行します。

## 前提条件

- Codex CLIがインストール済み（`codex` コマンドが利用可能）
- PRが作成済み

## レビュー実行

以下のコマンドでCodexレビューを実行：

```bash
codex exec --sandbox read-only "You are acting as a reviewer for a proposed code change made by another engineer. Focus on issues that impact correctness, performance, security, maintainability, or developer experience. Flag only actionable issues introduced by the change. When you flag an issue, provide a short, direct explanation and cite the affected file and line range. Prioritize severe issues and avoid nit-level comments unless they block understanding of the diff. After listing findings, produce an overall correctness verdict ('patch is correct' or 'patch is incorrect') with a concise justification and a confidence score between 0 and 1. Review the current branch against origin/main. Use git merge-base to find the merge base, then review the diff from that merge base to HEAD."
```

## レビュー結果の対応

1. **verdict が "patch is correct"** の場合
   - そのまま完了

2. **verdict が "patch is incorrect"** の場合
   - 指摘された問題を確認
   - 修正が必要な場合は修正してコミット・プッシュ
   - 再度Codexレビューを実行

3. **重大な問題が指摘された場合**
   - セキュリティ問題: 必ず修正
   - パフォーマンス問題: 影響度を評価して対応
   - 保守性の問題: 可能な範囲で対応

## レビュー結果の報告

レビュー完了後、以下の形式で報告する：

```
## Codex Review

- Verdict: [patch is correct / patch is incorrect]
- Confidence: [0〜1のスコア]
- 指摘事項: [件数]件（対応済み）
```
