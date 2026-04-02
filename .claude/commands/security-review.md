---
description: 5観点コードレビュー（Security / Performance / Quality / Accessibility / AI Residuals）
allowed-tools: Read, Grep, Glob, Bash(git:*), Bash(grep:*), Bash(wc:*)
argument-hint: '[--scope FILE_OR_DIR] [--base-ref REF]'
---

# Code Review Command

変更差分を5観点でレビューし、severity ベースの verdict（APPROVE / REQUEST_CHANGES）を返す。

## Step 1: レビュー対象の特定

引数に応じてレビュー対象を決定する。

```bash
# --base-ref が指定されている場合
git diff --name-only --diff-filter=ACMR ${BASE_REF}

# --scope が指定されている場合
# 指定されたファイル/ディレクトリのみ対象

# どちらもない場合: ステージング差分 → 直近コミット差分 → main との差分
git diff --cached --name-only --diff-filter=ACMR
# ステージングが空なら
git diff --name-only --diff-filter=ACMR HEAD~1
# それも空なら
git diff --name-only --diff-filter=ACMR main...HEAD
```

差分がない場合はレビュー不要としてメッセージを表示して終了する。

## Step 2: 差分の収集

```bash
git diff --stat ${BASE_REF:-HEAD~1}
git diff ${BASE_REF:-HEAD~1} -- ${CHANGED_FILES}
```

## Step 3: AI Residuals の静的走査

変更ファイルに対して以下のパターンを検索する。

### Major（出荷リスク）

```
localhost|127\.0\.0\.1|0\.0\.0\.0   # ローカルアドレス
it\.skip|describe\.skip|test\.skip  # スキップされたテスト
PRIVATE_KEY|SECRET_KEY|PASSWORD=    # ハードコードされた秘密情報候補
staging\.|dev\.|sandbox\.           # 環境固定 URL
```

### Minor（残骸候補）

```
mockData|dummyData|fakeData|testData  # テストデータ残骸
TODO|FIXME|HACK|XXX                   # 未対応マーカー
```

### Recommendation（仮実装）

```
temporary|placeholder|replace.later|workaround  # 仮実装コメント
```

各ヒットのファイル名・行番号・該当行を記録する。

## Step 4: 5観点レビュー

変更差分を以下の5観点で評価する。

### 4.1 Security

- SQL インジェクション（文字列結合によるクエリ構築）
- XSS（未サニタイズの出力）
- 機密情報露出（API キー、トークン、パスワードのハードコード）
- 入力バリデーション不足（外部入力の未検証使用）
- 認証・認可の欠落（エンドポイントの保護漏れ）

### 4.2 Performance

- N+1 クエリ（ループ内の DB アクセス）
- 不要な再レンダリング（依存配列の誤り、メモ化の欠落）
- メモリリーク（イベントリスナーの未解除、タイマーの未クリア）
- 非効率なアルゴリズム（O(n²) 以上の計算量）
- 大きなバンドル影響（不要な import、tree-shaking 阻害）

### 4.3 Quality

- 命名の明瞭さ（意図が伝わる命名か）
- 単一責任の遵守（1関数/1クラスが1つの責務か）
- テストカバレッジ（変更コードに対するテストの存在）
- エラーハンドリング（例外の適切な捕捉と処理）
- コードの重複（DRY 違反）

### 4.4 Accessibility

- ARIA 属性（インタラクティブ要素の適切なラベル付け）
- キーボードナビゲーション（フォーカス管理、Tab 順序）
- カラーコントラスト（WCAG AA 基準）
- セマンティック HTML（div/span の乱用）
- フォーム要素のラベル（`<label>` の紐付け）

### 4.5 AI Residuals

Step 3 で検出したパターンに加え、文脈を考慮して判定する。

- テストファイル内の `mockData` は正当な使用（minor にしない）
- `.env.example` 内の `localhost` は正当な使用（major にしない）
- コメント内の `TODO: #123` は Issue 紐付きなら recommendation に留める

## Step 5: Verdict 判定

以下の基準で verdict を決定する。

| 条件                        | Verdict             |
| --------------------------- | ------------------- |
| critical が 1件以上         | **REQUEST_CHANGES** |
| major が 1件以上            | **REQUEST_CHANGES** |
| minor / recommendation のみ | **APPROVE**         |

## Step 6: レビュー結果の出力

以下のフォーマットでレビュー結果を出力する。

```
## Code Review Result

**Verdict**: APPROVE / REQUEST_CHANGES

### Summary
- Files reviewed: {N}
- Issues found: {critical}C / {major}M / {minor}m / {recommendation}R

### Critical Issues
（critical があれば severity 順に表示）

### Major Issues
（major があれば表示）

### Observations
（minor / recommendation を表示）

| Severity | Category | Location | Issue | Suggestion |
|----------|----------|----------|-------|------------|
| minor | Quality | src/foo.ts:42 | ... | ... |

### AI Residuals Summary
（Step 3 の検出結果サマリ）
```

## 注意事項

- minor / recommendation だけで REQUEST_CHANGES にしない
- 証拠のない懸念は major にしない（推測ではなく根拠を示す）
- テストファイル内のモックデータは正当な使用として除外する
- 設定ファイル（`.env.example` 等）のローカルアドレスは除外する
