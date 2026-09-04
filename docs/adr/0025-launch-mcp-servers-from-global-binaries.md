# ADR 0025: MCP サーバーを npx ではなくグローバル導入済みバイナリで起動する

## Status

Accepted

## Context

このリポジトリが管理する MCP サーバー定義（`script/fix-mcp-token-exposure.sh`）は、
起動コマンドを `npx -y <pkg>@latest` の形で組み立てていた。導入不要で常に最新版が
使えるのが利点だったが、実運用で 2 つの問題が出た。

**1. 起動が遅く、タイムアウトに達する。** `@latest` は起動のたびにレジストリ解決を
走らせる。2026-09-04 (JST) の freee MCP 復旧時に実測したところ、初回相当の起動に 20.0 秒
かかっていた。Claude Code の MCP 起動タイムアウトは 30 秒で、余裕がほとんどない。

**2. 共有 npx キャッシュが壊れると起動そのものが失敗する。** 複数の MCP 定義が
`npm_config_cache` に同じディレクトリ（`$TMPDIR/mcp-npm-cache`）を指定しており、
並行起動でパッケージ展開が衝突する。2026-09-05 未明 (JST) に `slack` と `sentry-elu` が同時に
`CONNECTION_CLOSED` になった件は、認証でも遅延でもなく、この破損だった。

```text
npm error ENOTEMPTY: directory not empty, rename
  '.../mcp-npm-cache/_npx/2f12aed4e6049c73/node_modules/slack-mcp-server-darwin-arm64'
  -> '.../node_modules/.slack-mcp-server-darwin-arm64-BckzTq74'
```

`npx` はこの状態から自力で回復しないため、キャッシュを手で消すまで起動し続けられない。
つまり `npx` 起動は「遅い」だけでなく「一度壊れると自然治癒しない」構成だった。

## Decision

**stdio 起動の MCP サーバーは、グローバル導入済みバイナリを絶対パスで直叩きする。**

```sh
npm i -g @sentry/mcp-server
```

- 絶対パスを埋める。MCP は login shell から spawn されるが、その PATH に npm の
  global bin（この Mac では `~/.local/bin`）が入っていないことを実測で確認した。
  PATH 解決に頼ると環境によって解決できない。
- パスは **定義生成時** に `npm prefix -g` から解決して埋め込む。起動時に `npm` を
  呼ぶと、削ったはずの起動コストを戻してしまう。
- 資格情報の渡し方は変えない。ADR の対象は起動方法だけで、トークンは引き続き
  環境変数経由で渡す（argv に載せない）。

このリポジトリが管理するのは `sentry-elu` だけである。`slack` は
`script/fix-mcp-token-exposure.sh` の管理対象外で、登録は各マシンの
`~/.claude.json` にしかない（トークンを argv に載せておらず、この
スクリプトが直す対象ではないため）。同じ方針を手で適用しており、前提は
`npm i -g slack-mcp-server` になる。

リモート MCP（`mcp-remote` 経由の linear / supabase）は今回の対象外とする。これらは
`mcp-remote` というパッケージ 1 つを共有しており、置き換えの利得が小さい。

## Consequences

- 起動時間が短くなった。実測で `slack` 0.80 秒 / `sentry-elu` 0.28 秒（いずれも
  `initialize` の応答までの時間）。`npx` 版は破損により応答なし。
- **自動更新が失われる。** `@latest` をやめたので、更新は `npm i -g` を明示的に
  実行する必要がある。これは受け入れるトレードオフで、起動の確実性と引き換えにする。
- グローバル導入が前提条件になる。未導入のまま定義を適用すると `claude mcp list` で
  Failed になる。`script/fix-mcp-token-exposure.sh --help` に前提を明記した。
