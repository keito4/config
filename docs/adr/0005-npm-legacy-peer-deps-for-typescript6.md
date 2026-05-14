# ADR-0004: npm --legacy-peer-deps によるTypeScript 6.x ピア依存競合の解消

- **Date**: 2026-05-11
- **Status**: Accepted

## Context

`npm/global.json` の自動更新により `typescript@6.0.3`（メジャーバージョン）に更新された。
`typescript-language-server@5.x` は `peerDependencies` で `typescript@^5.x` を宣言しており、
`typescript@6.x` との組み合わせで `npm ERESOLVE` が発生し、Docker ビルドが失敗した。

失敗した CI: Container Security Scan on main (2026-05-11T13:06 UTC, commit c0470fc)

## Decision

Dockerfile の `npm install -g` に `--legacy-peer-deps` フラグを追加する。

合わせて、`typescript` と `typescript-language-server` を他のパッケージと同様に
`npm/global.json` からバージョンをピン留めして再現性を確保する。

## Consequences

- **良い点**: TypeScript メジャーバージョンアップ時にも typescript-language-server が
  追従するまでの間、Docker ビルドが継続できる
- **良い点**: `npm/global.json` で全パッケージのバージョンを一元管理できる
- **悪い点**: `--legacy-peer-deps` はピア依存の不整合を隠蔽するため、
  実際の互換性問題が実行時まで顕在化しない可能性がある
- **代替案**: `typescript-language-server` を TypeScript 6.x に対応した新版へ更新する
  （更新版がリリースされた際に実施する）
