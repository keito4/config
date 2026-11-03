# ADR 0033: macOS Node のセキュリティ修正を公式バイナリで固定する

## Status

Proposed

## Context

Home Manager の Node 24.13.0 は CVE-2026-111497 の修正前である。
現在の nixpkgs lock を更新すると Node 以外のツールも更新されるため、
今回の対応ではランタイムだけを変更する。

既存の Nix パッケージは Brotli を共有ライブラリとして利用する。
Node のソースバージョンだけを上書きしても、古い Brotli が残りうる。
現行 flake が対象とするシステムは aarch64-darwin のみである。

## Decision

Home Manager の `nodejs_24` を、Node.js 公式の macOS arm64 版
24.22.2 を使う小さな Nix パッケージに置き換える。
公式の SHA256 を固定し、バイナリと同梱ライブラリを変更せずインストールする。
ビルド時に Node のバージョン、npm の起動、Brotli の圧縮・展開を確認する。

公式の修正済みバイナリでも `process.versions.brotli` は 1.2.0 と表示される。
修正判定にはその表示値ではなく、修正リリースと公式ハッシュを用いる。
Brotli の往復テストは動作確認であり、脆弱性の再現テストではない。

## Consequences

- flake.lock と Node 以外のパッケージは変更しない。
- このパッケージは aarch64-darwin 専用となる。
- Node の更新は当面この pin と SHA256 の手動更新が必要となる。
- nixpkgs の Node と共有 Brotli の両方が修正済みになったら、
  ビルドと実バージョンを確認して `nodejs_24` に戻し、このパッケージを削除する。
- パッケージのビルドとホストへの切替は別工程とし、切替後には Node を使う
  常駐プロセスの再起動も必要である。

## References

- [Issue #1435](https://github.com/keito4/config/issues/1435)
- [Node.js October 2026 security releases](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases)
- [Node.js 24.22.2](https://nodejs.org/en/blog/release/v24.22.2)
- [Official SHA256 checksums](https://nodejs.org/dist/v24.22.2/SHASUMS256.txt)
