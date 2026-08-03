---
name: weekly-ingest
description: API非提供のサイト・アプリから Playwright によるブラウザ自動操作で週次データ取り込み（口座残高など）を行い、しきい値判定と Slack 通知まで実行する。週次 Routine または /weekly-ingest 実行時に適用すること。
---

# Weekly Ingest Skill

`automation/adapters/` に定義されたサイトを巡回し、API が提供されていない情報（口座残高・ポイント残高・利用明細など）を取得して、しきい値チェックと Slack 通知を行います。

## 前提

- アダプタ定義: `automation/adapters/*.yaml`（`_` 始まりのファイルはテンプレートなのでスキップ）
- 判定ルール: `automation/rules.yaml`
- 認証情報: Doppler（`doppler secrets get`）または環境変数から解決。値はリポジトリ・ログ・通知に書かず、必ずマスクする

## 実行フロー

1. **アダプタ読み込み**: `automation/adapters/*.yaml` を列挙し、`enabled: true` のものだけを対象にする
2. **認証情報解決**: `auth.secret` に指定されたシークレット名から ID / パスワード（必要なら TOTP シークレット）を取得
3. **データ取得**: Playwright（MCP ツールまたはスクリプト）で `steps` に従いログインし、`metrics` の値を取得
4. **正規化**: `{site, metric, value, unit, fetched_at}` の形に揃える
5. **ルール判定**: `automation/rules.yaml` の条件を評価（例: `balance < 100000`）
6. **通知**: Slack へ送信
   - しきい値割れ: 即アラート（サイト名・メトリクス・現在値・しきい値・メッセージ）
   - 正常時: 全サイトの週次サマリを 1 通にまとめて投稿
7. **記録**: 実行結果スナップショットを `.context/weekly-ingest/<date>.json` に保存

## 失敗時の対応

| 状況                     | 対応                                                                       |
| ------------------------ | -------------------------------------------------------------------------- |
| ページ遷移・セレクタ失敗 | スクリーンショットを `.context/weekly-ingest/` に保存し、最大 2 回リトライ |
| ログイン失敗             | **リトライ禁止**（アカウントロック防止）。Slack で手動確認を依頼           |
| レイアウト変更を検知     | アダプタの修正案を提示、または Issue を起票                                |
| CAPTCHA / 追加認証       | 自動回避を試みず、Slack に通知して該当サイトをスキップ                     |

## 禁止事項

- 参照系操作のみ。振込・購入・設定変更など書き込み系の操作は絶対に実行しない
- 認証情報・セッション Cookie を平文でログ・コミット・通知に含めない
- CAPTCHA・不正検知の回避を試みない
- ログイン失敗の連続リトライ

## 週次スケジュール登録（初回のみ）

Claude Code Remote の Routine として登録する:

- cron: `0 22 * * 0`（UTC 指定。JST 月曜 07:00）
- create_new_session_on_fire: true
- prompt: 「weekly-ingest スキルを適用して週次取り込みを実行してください」

n8n の Schedule Trigger から起動する構成でもよい。

## 新しいサイトの追加

`automation/adapters/_example.yaml` をコピーして項目を埋める。スキーマ詳細は [automation/README.md](../../../automation/README.md) を参照。
