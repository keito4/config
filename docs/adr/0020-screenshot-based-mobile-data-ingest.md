# ADR 0020: Screenshot-Based Mobile Data Ingest

## Status

Accepted

## Context

ADR 外だが既存の週次取り込み基盤として `weekly-ingest` スキル
（`.claude/skills/weekly-ingest.md` + `automation/adapters/`）があり、これは
Playwright によるブラウザ自動操作を前提とする。そのため Web 版が存在しない
スマホ専用アプリ（銀行・証券アプリの残高、iOS スクリーンタイムなど）の
データはクラウドから到達できず、個人 KPI（週次やり切り率・集中時間確保率）
の計測に必要な入力が欠けていた。

検討した取り込み経路は 3 つ:

1. iOS ショートカット → Webhook（初期設定が重く、アプリ側の共有機能に依存）
2. スクリーンショットを Slack に投稿 → 画像読み取り（どのアプリにも適用可能、
   ユーザーの手間はスクショ 1 枚）
3. Slack リマインダーへの手入力返信（転記ミス・継続率に難）

## Decision

経路 2 を採用し、`screenshot-ingest` スキルとして weekly-ingest と並列の
仕組みを追加する:

- **定義** `automation/screenshots/*.yaml` に取り込み対象アプリを宣言的に
  管理する（`source` / `app` / `metrics` / `capture_hint`）。`_` 始まりは
  テンプレート。
- **インボックス** ユーザーは Slack のプライベートチャンネル
  `#kpi-screenshot-inbox` にスクショを投稿するだけでよい。
- **実行** 週次 Routine が直近 7 日分の投稿画像を視覚的に読み取り、
  `{source, metric, value, unit, captured_at, fetched_at}` に正規化する。
  土曜夜にリマインダー、日曜朝（週次レビュー前）に取り込みを実行する。
- **判定・通知・記録** しきい値ルールは `automation/rules.yaml` を
  weekly-ingest と共用し、結果は Slack サマリ + `.context/screenshot-ingest/`
  スナップショット（+ 任意で Notion ページ追記）に記録する。

画像そのものはコミットせず数値のみを記録する。スクショに写り込む口座番号
などの識別子は読み取り対象外とし、ログ・通知ではマスクする。

## Consequences

### Positive

- Web 版のないアプリでも、ユーザーの手間をスクショ投稿 1 回/週に抑えて
  KPI 入力データを取り込める。
- アダプタ・ルールが宣言的なので、対象アプリの追加が YAML 1 ファイルで済む。
- しきい値判定・通知・記録の流れを weekly-ingest と共通化でき、運用が同型。

### Negative

- 取り込みはユーザーのスクショ投稿に依存し、未投稿週は欠測になる。
- 画像読み取りは OCR 的な誤読リスクがあり、レイアウト変更で定義の
  メンテナンスが必要になる。

### Mitigation

- 週次サマリで「未提出」を明示し、土曜夜のリマインダー Routine で投稿を促す。
- 読み取りに自信がない値は確定記録せず、Slack スレッドで確認するフローを
  スキルに規定した。
