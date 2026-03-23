---
description: Analyze code similarity in the repository to detect duplicate functions and patterns
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(gh:*), Bash(similarity-ts:*)
arguments:
  - name: path
    description: Target path to analyze (default: current directory)
    required: false
  - name: threshold
    description: Similarity threshold 0.0-1.0 (default: 0.8)
    required: false
  - name: auto-refactor
    description: Automatically refactor and create PRs for each similarity (default: false)
    required: false
  - name: base-branch
    description: Base branch for PRs (default: main)
    required: false
---

# Code Similarity Analysis

リポジトリ内のコード類似度を分析し、重複した関数やパターンを検出します。

## 実行手順

1. **similarity-ts のインストール確認**

similarity-ts が未インストールの場合、オンデマンドでインストールします:

```bash
if ! command -v similarity-ts &>/dev/null; then
  echo "similarity-ts が未インストールです。インストールを開始します..."
  if command -v cargo-binstall &>/dev/null; then
    cargo binstall similarity-ts -y
  elif command -v cargo &>/dev/null; then
    cargo install similarity-ts
  else
    echo "Rust ツールチェインが必要です: curl -sSf https://sh.rustup.rs | sh"
    exit 1
  fi
fi
```

2. **similarity-ts コマンドを実行**

```bash
similarity-ts ${path:-.} --threshold ${threshold:-0.8} --print --exclude node_modules --exclude dist --exclude .git --exclude coverage
```

2. **分析結果の解釈**

検出された類似コードについて、以下の観点でレポートを作成してください：

### レポート形式

#### 概要

- 分析対象パス: `$path`
- 類似度閾値: `$threshold`
- 検出された類似ペア数

#### 類似度の高いコード一覧

| ファイル1 | ファイル2 | 類似度 | 推奨アクション         |
| --------- | --------- | ------ | ---------------------- |
| path:line | path:line | 0.XX   | 共通化/リファクタ/許容 |

#### 詳細分析

各類似ペアについて：

- **類似箇所の説明**: どの部分が類似しているか
- **リファクタリング提案**: 共通化の具体的な方法
- **優先度**: High / Medium / Low

#### リファクタリング推奨事項

1. 即座に対応すべき重複（類似度 95%以上）
2. 共通関数への抽出を検討すべきもの（類似度 85-95%）
3. 許容可能な類似（意図的な重複や、共通化のコストが高いもの）

## オプション

追加のオプションが必要な場合は以下を参照：

- `--types`: 型定義の類似度もチェック
- `--classes`: クラスの類似度もチェック
- `--min-lines <N>`: 最小行数でフィルタ（デフォルト: 3）
- `--filter-function <NAME>`: 特定の関数名でフィルタ

## 自動リファクタリングとPR作成（--auto-refactor オプション）

`--auto-refactor` オプションを指定すると、検出された類似コードに対して自動的にリファクタリングを実施し、各類似ペアごとに別々のPRを作成します。

### Step 1: 類似コードの検出

```bash
similarity-ts ${path:-.} --threshold ${threshold:-0.8} --print --exclude node_modules --exclude dist --exclude .git --exclude coverage
```

### Step 2: 類似ペアの分類

検出された類似ペアを優先度別に分類：

1. **High Priority** (類似度 95%以上): 即座にリファクタリング推奨
2. **Medium Priority** (類似度 85-95%): 共通関数への抽出を検討
3. **Low Priority** (類似度 85%未満): レビューのみ

### Step 3: 各類似ペアごとにリファクタリング

各類似ペア（High/Medium Priority）について：

#### 3.1 ブランチ作成

```bash
# 最新のベースブランチを取得
git fetch origin ${base-branch:-main}

# リファクタリング用のブランチを作成
git checkout -b refactor/similarity-${PAIR_ID}-$(date +%Y%m%d%H%M%S) origin/${base-branch:-main}
```

#### 3.2 共通関数の抽出

1. 類似コードの共通部分を特定
2. 共通関数を作成（適切な場所に配置）
3. 既存のコードを共通関数の呼び出しに置き換え

#### 3.3 テストの実行

```bash
# リファクタリング後、テストを実行
npm test

# もしくは
npm run test:unit
```

テストが失敗した場合：

- リファクタリングを調整
- テストを修正
- 再度実行

#### 3.4 コミットとPR作成

```bash
# 変更をコミット
git add .
git commit -m "refactor: Extract common function for ${DESCRIPTION}

類似度: ${SIMILARITY}%
ファイル1: ${FILE1}:${LINE1}
ファイル2: ${FILE2}:${LINE2}

## リファクタリング内容

${REFACTORING_DETAILS}

## 影響範囲

- ${AFFECTED_FILES}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# リモートにプッシュ
git push -u origin refactor/similarity-${PAIR_ID}-$(date +%Y%m%d%H%M%S)

# PRを作成
gh pr create \
  --base ${base-branch:-main} \
  --title "refactor: Extract common function for ${DESCRIPTION}" \
  --body "$(cat <<EOF
## 概要

類似コード分析で検出された重複コードをリファクタリングしました。

## 類似度情報

- **類似度**: ${SIMILARITY}%
- **優先度**: ${PRIORITY}
- **ファイル1**: ${FILE1}:${LINE1}
- **ファイル2**: ${FILE2}:${LINE2}

## リファクタリング内容

${REFACTORING_DETAILS}

### 抽出した共通関数

\`\`\`typescript
${COMMON_FUNCTION_CODE}
\`\`\`

### 変更箇所

- ${FILE1}: ${CHANGES_FILE1}
- ${FILE2}: ${CHANGES_FILE2}

## テスト

- ✅ ユニットテスト: 通過
- ✅ リファクタリング前後の動作: 同一

## 影響範囲

- 変更ファイル数: ${AFFECTED_FILES_COUNT}
- コード削減: ${LINES_REMOVED} 行削減

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 4: サマリーレポート

すべてのリファクタリングが完了した後、サマリーレポートを表示：

```
✅ Similarity Analysis and Refactoring Complete!

## 分析結果

- 分析対象パス: ${path}
- 類似度閾値: ${threshold}
- 検出された類似ペア数: ${TOTAL_PAIRS}

## リファクタリング結果

- High Priority: ${HIGH_COUNT} ペア → ${HIGH_PR_COUNT} PR作成
- Medium Priority: ${MEDIUM_COUNT} ペア → ${MEDIUM_PR_COUNT} PR作成
- Low Priority: ${LOW_COUNT} ペア → レビューのみ

## 作成されたPR

${PR_LIST}

## 統計

- 総コード削減: ${TOTAL_LINES_REMOVED} 行
- 共通関数数: ${COMMON_FUNCTIONS_COUNT}
- テスト通過率: 100%

次のステップ:
1. 各PRの内容を確認
2. CIチェックの結果を確認
3. コードレビューを依頼
4. 順次マージ
```

## 使用例

### 基本的な分析（レポートのみ）

```bash
/similarity-analysis
```

### カスタム閾値で分析

```bash
/similarity-analysis --threshold 0.9
```

### 自動リファクタリングとPR作成

```bash
/similarity-analysis --auto-refactor
```

### 特定パスを対象に自動リファクタリング

```bash
/similarity-analysis --path src/utils --threshold 0.85 --auto-refactor
```

### カスタムベースブランチでPR作成

```bash
/similarity-analysis --auto-refactor --base-branch develop
```

## 注意事項

- node_modules, dist, .git, coverage ディレクトリは自動的に除外されます
- TypeScript/JavaScript ファイルが対象です
- 類似度が高いからといって必ずしもリファクタリングが必要とは限りません
- `--auto-refactor` オプションは慎重に使用してください
  - テストが存在するプロジェクトで使用することを推奨
  - リファクタリング後は必ず手動でもレビューしてください
- 各PRは独立しているため、個別にレビュー・マージ可能です
