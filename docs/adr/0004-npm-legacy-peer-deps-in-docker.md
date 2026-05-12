# ADR 0004: Docker ビルドの npm install に --legacy-peer-deps を使用

## Status

Accepted

## Context

`.devcontainer/Dockerfile` では `npm install -g` でグローバル CLI ツール群（typescript, typescript-language-server, eslint, @openai/codex, vercel, 等）をインストールしている。

2026-05-08 に TypeScript 6.0 がリリースされ、`npm/global.json` の自動更新により `typescript@6.0.3` が採用された。しかし `typescript-language-server@5.2.0` の peer dependency が `typescript: ">=4.4.0 <6.0.0"` に相当する制約を持つため、npm 7+ のデフォルト動作（peer dep conflict で ERESOLVE エラー）により Docker build が失敗するようになった。

失敗の特徴：

- npm install が約 2.9 秒で終了（パッケージダウンロード前に解決フェーズで失敗）
- exit code: 1

## Decision

`npm install -g` に `--legacy-peer-deps` フラグを追加する。

このフラグは npm v3 以前の動作（peer dep の不整合を警告のみ）を再現し、peer dep 制約に違反するパッケージの組み合わせでもインストールを続行させる。

## Consequences

### Positive

- Docker build が TypeScript 6.x と typescript-language-server 5.x の組み合わせで成功する
- `npm/global.json` の自動更新スクリプトを変更不要
- peer dep が解消される新しい typescript-language-server リリース後に自然に不要になる

### Negative

- peer dep の不整合が実行時エラーとして顕在化する可能性がある（ただし CLI ツールとして動作する範囲では影響は限定的）

### Neutral

- `--legacy-peer-deps` は npm が廃止を計画していないオプション（npm 8+ でも継続サポート）
- typescript-language-server が TypeScript 6.x に対応したメジャーリリースをした際は、このフラグを外すことを検討する
