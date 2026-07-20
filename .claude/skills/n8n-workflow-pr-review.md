---
description: keito4-org/n8n_custom_node の n8n ワークフロー/テンプレートPRをレビューする。ワークフロー同期PR（workflow-sync/*）の退行判定、資格情報のMASKED破損チェック、typeVersion・.item/.first() の意味論判定、lockfile起因のCI失敗の切り分けを行う。n8nのPRレビュー・マージ可否判断を依頼されたときに使う。
---

# n8n ワークフローPRレビュー

対象リポジトリ: `keito4-org/n8n_custom_node`（テンプレートの正本）
ワークフロー実体は elu / OYKOT の n8n インスタンスにあり、リポジトリのテンプレートJSONと双方向に同期される。

## 0. PRの分類

まず種別を判定する。判断基準が異なる。

| 種別             | 見分け方                                      | 判断基準                           |
| ---------------- | --------------------------------------------- | ---------------------------------- |
| ワークフロー同期 | ブランチ `workflow-sync/*`、`*.template.json` | **退行していないか**（下記1〜3）   |
| ワークフロー修正 | 人手の `fix:`/`feat:` + `*.template.json`     | 意図通りか＋正常系の配線が無変更か |
| パッケージ更新   | `package.json` / `pnpm-lock.yaml`             | CI green＋lockfile整合＋peer整合   |

## 1. 最優先: 資格情報のMASKED破損チェック

同期PRで**最も重大な退行**。これが混入していたら即クローズ。

```bash
gh pr diff <PR> | grep -i masked      # 0件であること
gh pr diff <PR> | grep -i credential  # 資格情報の書き換えが無いこと
```

n8n の API は資格情報を `"MASKED"` で返すため、**live → repo → live** の往復で資格情報が破壊される。
実害例: 2026-06 に `githubApi/common_github` が MASKED 化 → Issue作成が全件失敗。

## 2. 「同期PR＝退行」ではない — 差分の意味論を読む

同期PRは n8n UI での編集が機械的に落ちてくるだけなので、**差分の1行ずつが fix なのか退行なのかを判定する**。
機械的な「同期だから怪しい」判断はしない。

### `.item` → `.first()`

- `$('X').item` = paired item 解決。Switch/If の分岐をまたぐと解決に失敗して実行時エラーになりうる
  （関連: [n8n#14568](https://github.com/n8n-io/n8n/issues/14568)。**ソース未確認 — 一般論として鵜呑みにしない**）。
- `$('X').first()` = 常に先頭アイテム。例外を投げない。
- **アイテムが1件しか流れない場合、両者は等価** → 退行ではない。
- 複数アイテムが流れうる場合は、全アイテムが先頭の値で処理される**サイレントな退行**になる。
  Slackなら「別のユーザー宛に返信する」等の実害になり、CIでは検出できない。

一般論に頼らず、**そのワークフローで複数アイテムが流れうるか**を構造から確定させるのが確実。

判定手順 — fan-out ノードの有無とトリガー特性を必ず確認する:

```bash
F=packages/common_module/nodes/CommonModule/templates/<name>.template.json
# fan-out ノード（複数アイテム化）の有無
jq -r '.nodes[] | select(.type|test("splitOut|splitInBatches|itemLists|code|aggregate";"i")) | "\(.name)\t\(.type)"' $F
# トリガー種別
jq -r '.nodes[] | select(.type|test("trigger|webhook";"i")) | "\(.name)\t\(.type)"' $F
```

Slack Trigger / Webhook は1イベント=1アイテム。fan-out が無ければ `.first()` は安全。

### `typeVersion` の変化

n8n UI で開くと自動マイグレーションで上がる。**上がること自体は退行ではない**。
「どのバージョンで何の挙動が変わるか」を n8n のソースで裏取りしてから判定する。**推測しない**。

`n8n-nodes-base.executeWorkflow`（`version: [1, 1.1, 1.2, 1.3]` の単一クラス）で確認済みの事実:

- **`workflowInputs` は typeVersion で実行時ガードされていない。** バージョン条件は
  `displayOptions: { show: { '@version': [{_cnd:{gte:1.2}}] } }` ＝**エディタでの表示条件のみ**。
  実行時は `getNodeParameter` が `node.parameters` を生で読むため、**1.1 でも `workflowInputs` は効く**。
  → 「1.1 だからマッピングが死んでいる」は**誤り**。1.2 への引き上げ＝有効化、でもない。
- **1.3 が 1.2 に追加したのはエラー出力の統合のみ。** `outputIndex = nodeVersion >= 1.3 ? 0 : i`。
  **`onError: continueErrorOutput`（エラー出力モード）を使っているノードにしか影響しない。**
- サブWFへ渡るフィールドの絞り込みは、呼び出し側の typeVersion ではなく
  **サブWF側 `ExecuteWorkflowTrigger` の `inputSource`** が支配する（`passthrough` 以外なら schema に切り詰め）。
- 1.1 のままエディタで開くと `workflowInputs` が非表示のため、保存時に**JSONから消える恐れ**がある。
  1.2+ への引き上げはこの取りこぼしを防ぐ方向に働く。

→ 実務上の判定: **1.1→1.3 のバンプは、そのノードが `onError: continueErrorOutput` を使い
かつエラー出力を配線している場合のみ挙動が変わる。** それ以外は中立。

```bash
# typeVersion と、エラー出力モードを使っているか
jq -r '.nodes[] | select(.type=="n8n-nodes-base.executeWorkflow") | "\(.name)\ttypeVersion=\(.typeVersion)\tonError=\(.onError // "none")\thasWorkflowInputs=\(.parameters.workflowInputs != null)"' $F
# エラー出力の配線があるか（無ければ 1.3 の変更は無影響）
jq -r '.connections | to_entries[] | select(.key|test("Execute Workflow")) | "\(.key): -> \([.value.main[]?[]?.node])"' $F
```

出典: [ExecuteWorkflow.node.ts](https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/ExecuteWorkflow/ExecuteWorkflow/ExecuteWorkflow.node.ts) / [ExecuteWorkflowTrigger.node.ts](https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/nodes/ExecuteWorkflow/ExecuteWorkflowTrigger/ExecuteWorkflowTrigger.node.ts)

## 3. ワークフロー修正PRの検証

配線をJSONから直接検証する。PR説明を信用しない。

```bash
# エラー出力(main[1])がどこへ行くか / 正常系(main[0])が無変更か
jq -r '.connections | to_entries[] | select(.key|test("^Create an issue")) | "\(.key)\n  success-> \([.value.main[0][]?.node])\n  error  -> \([.value.main[1][]?.node])"' $F

# If ノードの true(main[0]) / false(main[1]) の接続先
jq -r '.connections | to_entries[] | select(.key|test("Guard")) | "\(.key): true->\([.value.main[0][]?.node]) | false->\([.value.main[1][]?.node])"' $F
```

チェック観点:

- **fail-safe か**: 条件不一致時の最悪ケースが「何もしない」に倒れているか（台帳を壊す方向でないか）
- **正常系が無変更か**: `main[0]` の配線に差分が無いこと
- `onError: continueErrorOutput` のエラー出力が、**理由を問わず**破壊的操作に直結していないか

## 4. CI失敗の切り分け — 自分の変更が原因か

**他PRのlockfile破損に巻き込まれている**ケースが多い。原因を必ず特定する。

```bash
gh pr view <PR> --json statusCheckRollup --jq '[.statusCheckRollup[]? | select(.conclusion=="FAILURE") | {name, detailsUrl}]'
gh run view --repo keito4-org/n8n_custom_node --job <jobId> --log-failed | grep -iE "ERR_PNPM|error|lockfile|frozen" | head
```

| エラー                       | 原因                                 | 対応                         |
| ---------------------------- | ------------------------------------ | ---------------------------- |
| `ERR_PNPM_BROKEN_LOCKFILE`   | lockfileの重複キー（自PRとは無関係） | 修正PRを先にマージ → rebase  |
| `ERR_PNPM_OUTDATED_LOCKFILE` | package.jsonとlockfileの不整合       | lockfile未更新。そのPRの欠陥 |
| `Generated Docs Sync` 失敗   | ノード数変更後にdocs未再生成         | **自PRの責任。下記で修正**   |

### Generated Docs Sync の直し方

ノードを増減させたら生成ドキュメントの再生成が必要。`pnpm` が無くても素の node で走る:

```bash
node scripts/generate-docs.js   # docs/GENERATED_TEMPLATES.md を更新
git add docs/GENERATED_TEMPLATES.md && git commit -m "docs: 生成ドキュメントを同期"
```

## 5. パッケージ更新PR

```bash
gh pr diff <PR>   # package.json だけで pnpm-lock.yaml が無い = frozen-lockfile で必ず落ちる
```

- **メジャーバンプは peer 依存を必ず確認**する。例: `@typescript-eslint/*` の peer は `typescript: '>=4.8.4 <6.1.0'` → TypeScript 7 は非適合。
  ```bash
  grep -A4 "'@typescript-eslint/parser@" pnpm-lock.yaml | grep typescript | head
  ```
- lockfile が壊れている間は dependabot が lockfile を更新できず、**package.json だけのPRが量産される**。
  lockfile修正を先にマージし、dependabot に作り直させる（`@dependabot recreate`）。

## 6. マージ順序

依存関係を解いてから流す。

1. lockfile / インフラ修正（他の全PRのCIをブロックしているもの）
2. rebase → CI green を確認 → ワークフロー修正
3. 同期PRは退行判定後

```bash
gh pr merge <PR> --squash --delete-branch
```
