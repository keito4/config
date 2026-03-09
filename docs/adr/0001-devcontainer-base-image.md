# ADR 0001: DevContainer Base Image Architecture

## Status

Accepted

## Context

開発環境の一貫性を確保するために、DevContainer/Codespaces 用のベースイメージが必要。
チーム間で同じ開発ツールとバージョンを使用することで、「私の環境では動く」問題を解消する。

## Decision

`ghcr.io/keito4/config-base:latest` をベースイメージとして提供する。

### 含まれるツール

| カテゴリ        | ツール        | バージョン管理  |
| --------------- | ------------- | --------------- |
| Runtime         | Node.js       | ARG + 自動更新  |
| Package Manager | pnpm          | ARG + 自動更新  |
| AI CLI          | Claude Code   | ARG + 自動更新  |
| AI CLI          | Codex         | npm/global.json |
| CLI             | GitHub CLI    | ARG + 自動更新  |
| CLI             | Doppler CLI   | ARG + 自動更新  |
| CLI             | 1Password CLI | ARG + 自動更新  |
| Language        | Rust          | rustup          |

### バージョン管理戦略

1. **Dockerfile ARG**: メジャーツールは ARG で管理し、GitHub Actions で自動更新 PR を作成
2. **npm/global.json**: npm パッケージは `update-libraries.yml` で自動更新
3. **DevContainer Features**: OS レベルのツールは Features で管理

## Consequences

### Positive

- 開発環境の一貫性が保証される
- 新しいバージョンが自動的にPRとして提案される
- チーム全体で同じツールバージョンを使用

### Negative

- イメージサイズが大きくなる（約 3GB）
- ビルド時間が長い（キャッシュなしで約 15 分）

### Mitigation

- GitHub Actions でキャッシュを活用
- マルチステージビルドの検討（将来）
