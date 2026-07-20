---
name: oykot-tasks
description: OYKOTのタスク(Todo)を確認・作成・更新するときに使う。担当者別のTodo整理、会議アクションのTodo化、期限・ステータス管理、Slackでの担当通知。Notion「✅【Common】TODO」DBが正本。
---

# OYKOT タスク(Todo)管理

OYKOTのタスクは Notion **✅【Common】TODO** DB が正本。会議のアクション項目のTodo化・担当者別整理・期限/ステータス管理はすべてここで行う。Notion MCP（`mcp__claude_ai_Notion__*`）でアクセスする。

## コアID

| 対象 | ID |
|---|---|
| TODO DB（ページ） | `13f70a52207f8054a6fcecc32d85cd38` |
| TODO データソース | `collection://cd06e8a4-ad5d-4316-8039-1ce565bd5568` |
| MEMBER データソース | `collection://7db22711-e49f-41b8-9cbe-be72701731ae` |
| OKR（目標管理）DB | `398ed17368ec497e9638af2c4d53bec9` ／ `collection://092ef8e4-0e78-43ed-8a34-e51d68a32fe8` |
| DOCUMENT（資料・計画）DS | `collection://69a06149-477a-4040-829b-da0847516c2e` |
| Notion運用ガイド（正本） | `39470a52207f81afb616e08a5917cda2` |

## TODO DB の主要プロパティ

- `name`（title）※SQLの列名は `name`
- `meta_assignees`（person）＝担当者。値は user ID の配列 `["user://<uuid>"]`
- `due_date`（date）＝期限。set/SQLは展開名 `"date:due_date:start"`（`YYYY-MM-DD`）
- `status`（status）＝ `未着手` / `進行中` / `ペンド` / `完了` / `アーカイブ`
- `description`（text）、`DOMAIN`/`MINUTES`/`OYKOT Project`/`REGULAR_MEETING`（relation）
- 便利ビュー：`Own all TODO`（自分の未完）、`by due date`、`Overdue`

## メンバー（担当者アサイン用・active）

| 氏名 | 通称 | 役割 | person user ID | Slack ID | メール |
|---|---|---|---|---|---|
| 佐藤 彗斗 | けいちゃん | 代表 | `user://b43fbb7b-818b-420c-bdd4-9ad44fba823f` | `U085D3BUX5X` | keito.sato@oykot.jp |
| 藤田 龍斗 | ryu-chan | エンジニア | `user://14cd872b-594c-8197-a4e8-0002dfb2f8ef` | `U0852T86U4C` | ryuto.fujita@oykot.jp |
| 赤松 藍 | ran-chan | 営業 | `user://13ad872b-594c-81ca-ac38-0002d49dad7e` | `U0850CHCG66` | ran.akamatsu@oykot.jp |
| Moeka Miyagawa | – | – | `user://29ed872b-594c-81fe-9fba-0002cc28de2d` | – | – |
| Ryuki Kurosawa | りゅうき | – | `user://362d872b-594c-81ef-80f2-0002aca44bc0` | – | – |

（最新はMEMBER DSを `SELECT name,nickname,person,meta_slack_id,email FROM ... WHERE is_active='__YES__'` で確認）

## ⚠️ 最重要の落とし穴：作成では担当・期限が保存されない

`mcp__claude_ai_Notion__notion-create-pages` で TODO を作ると、**`meta_assignees`(person) と `due_date` が保存されず、担当=作成者・期限=作成日に既定化される**（作成レスポンスは指定値をエコーするが、実体は反映されていない）。

必ず次の手順を踏む：
1. `notion-create-pages` で `name`/`status`/`description` を作成（parentは `{"type":"data_source_id","data_source_id":"cd06e8a4-ad5d-4316-8039-1ce565bd5568"}`）。
2. 作成された各ページに `notion-update-page`（`command: update_properties`）で `meta_assignees` と `date:due_date:start` を**上書き**する（update経由なら正しく保存される）。
3. SQLで検算する（下記）。

update例：
```
notion-update-page {
  page_id: "<created page id>",
  command: "update_properties",
  properties: { "meta_assignees": ["user://14cd872b-594c-8197-a4e8-0002dfb2f8ef"], "date:due_date:start": "2026-07-23" }
}
```
（期限を消すなら `"date:due_date:start": null`）

## クエリ（確認・検算）

`mcp__claude_ai_Notion__notion-query-data-sources`（SQLモード）を使う。
```sql
-- 担当者別の未完タスク
SELECT name, meta_assignees AS a, "date:due_date:start" AS due, status
FROM "collection://cd06e8a4-ad5d-4316-8039-1ce565bd5568"
WHERE status NOT IN ('完了','アーカイブ')
ORDER BY a, due
```
- person絞り込み：`meta_assignees LIKE '%b43fbb7b%'`（uuid先頭で十分）
- checkboxは `'__YES__'` / `'__NO__'`
- title列は `name`、期限は `"date:due_date:start"`

## 会議アクションのTodo化（運用ガイド準拠）

- 会議で出たアクションはTodo化し、担当者を**手動で必ず設定**（未設定時は作成者=会議オーナー）。
- 可能なら `MINUTES`（議事録）リレーションで紐付ける。
- 期限は明示されなければ「次回定例まで」を目安に置き、暫定である旨を残す。

## Slackで担当を通知

`mcp__slack__conversations_add_message` で投稿（**佐藤名義**・content_type `text/markdown`）。**送信前に本人確認**。担当を`<@SlackID>`でメンションする。
主な通知先：`#110_mgmt_mbo`(C0850D577TL) / `#170_mgmt_team`(C084XHW5XPF) / `#123_mgmt_meeting_weekly`(C084KT0HF4P)。

## 関連

- 目標(OKR)は目標管理DBが正。ただし過年度(FY25等)の残骸が混在し**SQLの直取得はノイズが多い**ので、ビュー（例「FY26 今月 自分のみ」）を使う。
- 計画・進め方のドキュメントは DOCUMENT DS（`69a06149-...`）に作成（例：行動規範WSフォローアップ）。
- OYKOT Notion全体の運用ルールは「📖 Notion運用ガイド（正本）」。
