# ADR 0022: Codex config.toml のマージ配備（symlink 廃止）

## Status

Accepted

## Context

`import.sh` は `.codex/config.toml` を `~/.codex/config.toml` へシンボリックリンクで
配備していた。しかし Codex / ChatGPT アプリは以下のような**端末固有の状態**を
`$CODEX_HOME/config.toml` 自体に書き戻す:

- `projects.*.trust_level`（ディレクトリ信頼の記録）
- `marketplaces.*`（プラグインマーケットプレイスのローカルパス・更新時刻）
- `plugins.*` の有効化状態
- `node_repl` / `computer-use` など絶対パス入りの MCP サーバー定義
- `notify` の通知クライアントパス

この結果、git 追跡ファイルが**コミットもできず消すこともできない恒久的な dirty**
になり、repo-sync-check（2026-08-05 導入）が「この端末にしか無い変更」として毎日
通知し続けていた（狼少年化）。

検討した選択肢:

1. **Codex 側のローカル上書き機構を使う** — 調査の結果、自動読み込みされる
   ローカル上書きファイルは存在しない。`-p` プロファイル
   （`$CODEX_HOME/<name>.config.toml`）は明示指定が必要で、デスクトップアプリは
   付与しない。`-c key=value` は CLI フラグのみ。さらにアプリが config.toml 自体へ
   書き込む以上、追跡ファイルへの symlink はどのみち成立しない。
2. **config.toml を生成物にし、ベース＋端末差分から組み立てる** — 採用。
3. **repo-sync-check に既知の端末固有ファイルの除外リストを持たせる** — 対症療法。
   dirty の根本原因が残り、本当に手当てが必要な変更の検知も鈍る。

## Decision

選択肢 2 を採用し、config.toml の配備を symlink から**深いマージによる実ファイル
生成**に変える:

- リポジトリの `.codex/config.toml` は**共有ベース**として追跡を維持する。
- `~/.codex/config.toml` は **Codex が所有する実ファイル**とし、端末状態は
  そこに蓄積させる（git からは不可視）。
- `config::import_codex` は symlink せず `script/codex-config-merge.py`
  （`uv run` / Python 3.11+ / tomli-w）で配備する。マージ規則は
  「テーブルは再帰マージ、**ベースが定義するキーはベース優先**、ローカルにしか
  無いキー（端末状態）は保持」。配備先が symlink の場合はリンク先の内容を
  取り込んだうえで実ファイルへ自動移行する（既存端末の移行パス）。
- `config::export_codex` は config.toml を対象外とする（端末状態のリポジトリへの
  逆流防止）。共有設定の変更はリポジトリの `.codex/config.toml` を直接編集する。
- `uv` が無い環境では、symlink の実ファイル化と新規シードのみ行い、マージは
  警告してスキップする。

## Consequences

- 各端末の `git status` が clean を維持でき、repo-sync-check の通知は本当に
  手当てが必要な変更だけになる。
- 共有設定の更新は `import.sh` 実行時にベース優先で各端末へ伝播する。
  ベースから**キーを削除**しても端末側には残る（マージは削除を伝播しない）点は
  許容する。必要なら端末側で手動削除する。
- 配備先ファイルは TOML 再シリアライズのためコメントを持たない。コメントの
  正本はリポジトリ側ベースにある。
- `codex features enable` などアプリ・CLI による設定変更は端末ローカルに
  閉じる。全端末へ配りたい設定はベースへの手動反映が必要になる。
