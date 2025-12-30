---
description: Analyze code similarity in the repository to detect duplicate functions and patterns
arguments:
  - name: path
    description: Target path to analyze (default: current directory)
    required: false
  - name: threshold
    description: Similarity threshold 0.0-1.0 (default: 0.8)
    required: false
---

# Code Similarity Analysis

リポジトリ内のコード類似度を分析し、重複した関数やパターンを検出します。

## 実行手順

1. **similarity-ts コマンドを実行**

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

## 注意事項

- node_modules, dist, .git, coverage ディレクトリは自動的に除外されます
- TypeScript/JavaScript ファイルが対象です
- 類似度が高いからといって必ずしもリファクタリングが必要とは限りません
