# ADR 0003: Rust ツールチェインをベースイメージから削除

## Status

Accepted

## Context

DevContainer ベースイメージのビルドが約40分かかっており、最大のボトルネックは arm64 QEMU エミュレーション下での `cargo install similarity-ts`（約20分）だった。Rust ツールチェイン（rustup, cargo, rustfmt, clippy）自体のインストールにも1-2分かかっていた。

similarity-ts は `/similarity-analysis` コマンドでのみ使用されており、ビルド時に `|| true` で失敗を許容していた。

## Decision

1. **similarity-ts をビルドから削除** — オンデマンドインストールに変更
2. **Rust ツールチェインをベースイメージから削除** — rustup, cargo, rustfmt, clippy, RUSTUP_HOME, CARGO_HOME
3. **Rust ビルド依存パッケージを削除** — pkg-config, libssl-dev

similarity-ts が必要な場合は `/similarity-analysis` コマンド実行時に `cargo binstall` または `cargo install` で自動インストールする。

## Consequences

### Positive

- ビルド時間が約20分短縮（40分 → 20分）
- イメージサイズが約200MB削減（Rust toolchain + similarity-ts）
- arm64 ビルドの QEMU ボトルネックが解消

### Negative

- `/similarity-analysis` コマンドの初回実行時に Rust のインストールが必要
- Rust を使うプロジェクトでは DevContainer features 等で別途インストールが必要

### Neutral

- `build-essential` は npm native addon のビルドに使用される可能性があるため残置
