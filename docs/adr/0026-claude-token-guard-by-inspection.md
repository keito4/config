# ADR 0026: 配布対象外リポジトリの Claude トークンガードは配布ではなく検査で担保する

## Status

Accepted

## Context

`anthropics/claude-code-action` は Claude の認証情報が無いままでも起動し、認証に失敗して赤で終わる。
呼び出し側のジョブは `continue-on-error: true` を付けているため、**ワークフローは緑・ジョブだけが黙って赤**になる。
keito4/calendar_alerm#88 と keito4/effectuation#5 がこれで、いずれもトークン失効から発覚まで日単位で放置された。

対策そのものは既にテンプレート（`templates/workflows/claude.yml` / `claude-code-review.yml`）に入っており、
認証情報が無いときは `if:` でステップを skip させている。問題は**その形が全リポジトリに行き渡っていない**ことである。

2026-09-06 に keito4 / Elu-co-jp / OYKOT-jp の非アーカイブ 91 リポジトリ（ワークフロー 362 本）を走査したところ、
未ガードは 13 リポジトリ 25 ファイル。うち 11 リポジトリは Elu-co-jp / OYKOT-jp にあり、
`.github/sync-downstream.json` の配布対象は keito4 の 5 リポジトリのみなので、**配布では届かない**。

配布で届かせる案（`sync-downstream.json` にクロスオーナーのリポジトリを足し、Org を跨いで書き込める
GitHub App を用意する）も検討したが、次の理由で採らない。

- Org 跨ぎの書き込み権限を 1 つの認証情報に集約すると、その失効・漏洩の影響範囲が一気に広がる
- 他 Org のリポジトリは所有者が別であり、ワークフローを無断で上書きされる前提を敷きたくない
- 未ガードの 25 ファイルは 10 通りに分岐しており、テンプレート全文の上書きは差分が大きく退行リスクが高い

## Decision

1. `script/lib/repo_maintenance_checks.sh` に `check_claude_token_guard` を追加し、
   `--check-claude-token-guard` で単体実行できるようにする。
   `anthropics/claude-code-action` を使うステップは、認証の可否を見る条件の配下にあることを要求する。
   認めるのは次の 3 形態のみ。
   - ステップの `if:` が `outputs.available` / `outputs.*token*` を **`== 'true'` の肯定形**で参照する
   - 同じジョブの `if:` が `needs.<job>.outputs.*` で同等の条件を持つ（keito4/effectuation の形）
   - **同じジョブで、action より前に** `script/validate-takt-auth.sh` 等が認証を検証して落とす
     （config 自身の scheduled-maintenance.yml の形）

   否定形（`!= 'true'` / `== 'false'`）と `||` を含む条件はガードとして認めない。
   いずれもトークンが無いときに action が動いてしまい、防ぎたい失敗をそのまま起こす。
   preflight もファイル内に名前が出るだけでは認めない。コメントや別ジョブの検証は、
   この action の実行を止められない。

2. `ci.yml` の Workflow Lint ジョブへ加え、このリポジトリとテンプレートの退行を PR で止める。
3. `Fleet Workflow Guards` の走査対象を keito4 だけでなく **Elu-co-jp / OYKOT-jp** へ広げる。
   配布できないリポジトリは、**週次の読み取り専用スキャンで未ガードを検出する**ことで担保する。
4. 既存の未ガード 25 ファイルは、テンプレート全文の上書きではなく
   **ガード step の挿入という最小差分**で各リポジトリへ個別 PR を出す。

## Consequences

- 配布経路（sync-downstream）と検査経路（fleet guards）で守備範囲が分かれる。
  配布対象は「テンプレートと同じ内容であること」、配布対象外は「ガードがあること」までを保証する。
- Fleet Workflow Guards は 3 オーナー分を回すため実行時間が伸びる（timeout を 15 分 → 30 分）。
  `CLAUDE_PAT` が Elu-co-jp / OYKOT-jp を読める必要がある。読めなければ discovery が非ゼロで落ちて気付ける。
- リポジトリ名はオーナーを跨いで一意ではない（`notion_mcp` は keito4 と OYKOT-jp の両方にある）ため、
  `repos` 入力は単一オーナー指定時のみ使える。
- 検査は読み取りのみで、対象リポジトリへ Issue も PR も作らない。検出後の修正は人間が着手する。
