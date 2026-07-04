# ADR 0017: ユーザーメモリー（~/.claude/CLAUDE.md）を config リポジトリ経由で配布する

## Status

Accepted

## Context

Claude Code のセッションは（特にリモート実行環境・DevContainer では）使い捨てコンテナで動作するため、`~/.claude/CLAUDE.md`（ユーザーレベルメモリー）に直接書いた内容はセッションを跨いで永続しない。一方で、Notion 運用マニュアル（📖 README｜Claude運用マニュアル）の常時参照ルールのように、**特定リポジトリに閉じない全環境共通の指示**を毎セッション自動で読み込ませたいという要求がある。

本リポジトリの Memory Management ルールでは「セッションを跨いで残す情報は git にコミットする」ことが定められており、auto memory や in-memory 状態への依存は禁止されている。

## Decision

`.claude/CLAUDE.md`（全社・全組織横断のベースライン）をユーザーメモリーの正本とし、以下の 2 経路で `~/.claude/CLAUDE.md` に配布する。

1. **DevContainer イメージビルド時**: `.devcontainer/Dockerfile` で `.claude/CLAUDE.md` を `/home/vscode/.claude/CLAUDE.md` に COPY する。
2. **セットアップスクリプト実行時**: `script/lib/claude_plugins.sh` の `plugins::sync_repo_content` で `.claude/CLAUDE.md` を `${CLAUDE_DIR}/CLAUDE.md` に常時上書きコピーする（commands / agents / hooks の同期と同列）。

全環境共通の指示（例: Notion Context の常時参照）は `.claude/CLAUDE.md` に追記し、git 経由で配布する。`~/.claude/CLAUDE.md` への手動編集は同期時に上書きされるため行わない。

## Consequences

### Positive

- 全リポジトリ・全環境（DevContainer / Codespaces / ローカル）のセッションで共通指示が自動的に読み込まれる。
- ユーザーメモリーが git 管理され、変更履歴・レビューが可能になる（Memory Management ルールと整合）。
- コンテナ再作成でもメモリーが失われない。

### Negative

- ホスト環境で `~/.claude/CLAUDE.md` を手動編集していた場合、`setup-claude.sh` 実行時に上書きされる。
- `.claude/CLAUDE.md` の変更が全環境に波及するため、誤った指示の影響範囲が広い。

### Mitigation

- 個人的・一時的な指示は `~/.claude/CLAUDE.md` ではなく本リポジトリの `.claude/CLAUDE.md` に PR 経由で追加し、レビューを通す。
- 配布はイメージ再ビルドまたは `setup-claude.sh` 再実行時に反映されるため、問題があれば git revert で全環境を巻き戻せる。
