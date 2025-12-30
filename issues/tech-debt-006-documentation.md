# Issue #006: ドキュメンテーションの改善

## 優先度

🟢 **低～中**

## 現状

### 良好な点 ✅

- **README.md**: 包括的 (379行)
- **CLAUDE.md**: 開発標準が明確に定義
- **SECURITY.md**: セキュリティガイドライン完備
- **.devcontainer/VERSIONING.md**: バージョニング戦略が明記

### 改善が必要な点 ❌

- **関数レベルのドキュメント**: 0%
- **インラインコメント**: 不足
- **アーキテクチャ決定記録 (ADR)**: 未実装
- **トラブルシューティングガイド**: 限定的
- **APIドキュメント**: なし（該当する場合）

## 問題の詳細

### ドキュメンテーションギャップ

#### 1. シェルスクリプトの関数ドキュメント

```bash
# 現状: ドキュメントなし
install_packages_darwin() {
  if type brew >/dev/null 2>&1; then
    brew bundle --file "$REPO_PATH/brew/MacOSBrewfile"
  fi
  # ...
}

# 理想: 構造化されたドキュメント
# macOS環境でのパッケージインストール
#
# Globals:
#   REPO_PATH: リポジトリのルートパス
# Arguments:
#   なし
# Returns:
#   0: 成功
#   1: Homebrewが見つからない場合
install_packages_darwin() {
  # ...
}
```

#### 2. 複雑なロジックのコメント不足

```bash
# export.sh L34-39: 何をしているのか不明瞭
sed -E '/^\[user\]/,/^\[/{
  s/^[[:space:]]*name[[:space:]]*=.*$/	# name = # Configure with: git config --global user.name "Your Name"/
  s/^[[:space:]]*email[[:space:]]*=.*$/	# email = # Configure with: git config --global user.email "your.email@example.com"/
  # ...
}' ~/.gitconfig > "$REPO_PATH/git/gitconfig"
```

#### 3. アーキテクチャ決定記録 (ADR) の欠如

- Zshを選択した理由
- DevContainerベースイメージの選択理由
- semantic-releaseの設定理由
- commitlintのカスタムルール設計

## 実装計画

### Step 1: 関数レベルのドキュメント追加（12時間）

**テンプレート**

```bash
# 関数の簡潔な説明
#
# Globals:
#   使用するグローバル変数のリスト
# Arguments:
#   $1: 引数の説明
#   $2: 引数の説明（オプション）
# Outputs:
#   標準出力への出力内容
# Returns:
#   0: 成功
#   1: エラー条件
# Example:
#   function_name arg1 arg2
function_name() {
  # 実装
}
```

**適用対象**

```bash
# script/lib/platform.sh
# platform::detect_os のドキュメント
# 現在のOSタイプを検出
#
# Globals:
#   OSTYPE: シェルによって設定されるOS識別子
# Arguments:
#   なし
# Outputs:
#   "linux" または "darwin" を標準出力
# Returns:
#   0: サポートされているOS
#   1: サポートされていないOS
platform::detect_os() {
  # ...
}

# script/lib/config.sh
# Claude設定をリポジトリからホームディレクトリにインポート
#
# 共有設定ファイル（settings.json, CLAUDE.md）と
# ディレクトリ（commands/, agents/, hooks/）をコピーする。
# ローカル専用ファイル（settings.local.json）は除外される。
#
# Globals:
#   なし
# Arguments:
#   $1: ソースディレクトリパス（必須）
#   $2: ターゲットディレクトリパス（デフォルト: $HOME/.claude）
# Outputs:
#   処理状況を標準出力
# Returns:
#   0: 成功
#   1: ソースディレクトリが存在しない
# Example:
#   config::import_claude "$REPO_PATH/.claude" "$HOME/.claude"
config::import_claude() {
  # ...
}
```

### Step 2: 複雑なロジックへのインラインコメント（4時間）

```bash
# script/export.sh の改善例

# Git設定から個人情報をフィルタリングしてエクスポート
if [[ -f ~/.gitconfig ]]; then
  # [user] セクション内の name, email, signingkey を
  # コメントアウトされたプレースホルダーに置換
  # これにより個人情報をリポジトリにコミットすることを防ぐ
  sed -E '/^\[user\]/,/^\[/{
    # name フィールドをコメント化し、設定方法のヒントを追加
    s/^[[:space:]]*name[[:space:]]*=.*$/	# name = # Configure with: git config --global user.name "Your Name"/

    # email フィールドをコメント化
    s/^[[:space:]]*email[[:space:]]*=.*$/	# email = # Configure with: git config --global user.email "your.email@example.com"/

    # signingkey フィールドをコメント化
    s/^[[:space:]]*signingkey[[:space:]]*=.*$/	# signingkey = # Configure with: git config --global user.signingkey "$(cat ~/.ssh\/id_ed25519.pub)"/
  }' ~/.gitconfig > "$REPO_PATH/git/gitconfig"

  echo "✅ gitconfig exported (personal info filtered)"
fi
```

### Step 3: ADRの導入（16時間）

**ディレクトリ構造**

```
docs/
└── adr/
    ├── README.md
    ├── template.md
    ├── 0001-use-zsh-for-shell-scripts.md
    ├── 0002-devcontainer-base-image.md
    ├── 0003-semantic-release-configuration.md
    ├── 0004-commitlint-custom-rules.md
    ├── 0005-credential-filtering-strategy.md
    └── 0006-claude-settings-separation.md
```

**テンプレート**

```markdown
# docs/adr/template.md

# [番号]. [タイトル]

Date: YYYY-MM-DD

## Status

[Proposed | Accepted | Deprecated | Superseded]

## Context

この決定が必要になった背景と問題を説明します。
技術的・ビジネス的な制約、既存の状況などを含めます。

## Decision

どのような決定を下したのかを明確に記述します。
選択した解決策とその理由を説明します。

## Consequences

この決定による影響を記述します。

### Positive

- メリット1
- メリット2

### Negative

- デメリット1
- デメリット2

### Neutral

- 中立的な影響1

## Alternatives Considered

検討した代替案とそれらを選ばなかった理由。

## Notes

追加情報、参考リンク、将来の検討事項など。
```

**ADR例: 0001-use-zsh-for-shell-scripts.md**

````markdown
# 1. Use Zsh for Shell Scripts

Date: 2024-08-15

## Status

Accepted

## Context

このリポジトリは環境設定の自動化にシェルスクリプトを使用しています。
Bash、Zsh、POSIX sh など複数の選択肢がありました。

主な要件:

- 配列の高度な操作
- 文字列操作の柔軟性
- ユーザーの対話シェルとの一貫性
- パス展開とグロビング

## Decision

Zshをスクリプトのデフォルトシェルとして使用します。

すべてのスクリプトは以下で開始します:

```bash
#!/usr/bin/env zsh
set -euo pipefail
```
````

## Consequences

### Positive

- **配列操作**: Bashより優れた配列処理（連想配列のサポート）
- **文字列操作**: 強力な文字列マニピュレーション機能
- **一貫性**: macOSのデフォルトシェル（Catalina以降）
- **モダン**: 最新の機能とアップデート

### Negative

- **ポータビリティ**: POSIX shより移植性が低い
- **学習曲線**: Bash経験者には若干の学習が必要

### Mitigation

- すべてのターゲット環境（macOS, Linux, DevContainer）でZshをインストール
- Zsh固有の機能を使用する場合は明示的にドキュメント化

## Alternatives Considered

### Bash

- **メリット**: より広く普及、多くのシステムでデフォルト
- **デメリット**: 配列操作がZshより劣る
- **却下理由**: macOSがZshをデフォルトに変更したため

### POSIX sh

- **メリット**: 最高の移植性
- **デメリット**: 機能が限定的、開発効率が低い
- **却下理由**: 複雑なロジックに不向き

## Notes

- Zsh 5.0以降を推奨
- `emulate -LR zsh` で Zsh モードを明示的に有効化可能（必要に応じて）
- ShellCheckでZsh特有の問題を検出可能

````

### Step 4: トラブルシューティングガイド（8時間）

```markdown
# docs/TROUBLESHOOTING.md

# トラブルシューティングガイド

## よくある問題と解決方法

### 1. import.sh 実行時のエラー

#### エラー: "Homebrew not found"
```bash
❌ FATAL: Required command not found: brew
````

**原因**: Homebrewがインストールされていない

**解決方法**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### エラー: "Permission denied"

```bash
cp: cannot create regular file '~/.claude/settings.json': Permission denied
```

**原因**: ホームディレクトリへの書き込み権限がない

**解決方法**:

```bash
# ディレクトリの権限確認
ls -la ~/.claude

# 権限修正
chmod 755 ~/.claude
```

### 2. export.sh 実行時の問題

#### 問題: クレデンシャルが誤ってエクスポートされた

**確認方法**:

```bash
# エクスポートされた .zshrc をチェック
grep -E 'TOKEN|SECRET|PASSWORD' "$REPO_PATH/dot/.zshrc"
```

**解決方法**:

```bash
# 該当行を削除
sed -i.bak '/NPM_TOKEN/d' "$REPO_PATH/dot/.zshrc"

# コミット前に再確認
npm test
```

### 3. DevContainer起動の問題

#### エラー: "Container failed to start"

**診断手順**:

```bash
# 1. Dockerログの確認
docker logs <container-id>

# 2. イメージの再ビルド
# VS Code: Cmd+Shift+P → "Dev Containers: Rebuild Container"

# 3. キャッシュクリア後に再ビルド
# VS Code: Cmd+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

### 4. CI/CDパイプラインのエラー

#### エラー: "Coverage threshold not met"

```
Jest: "global" coverage threshold for statements (70%) not met: 45%
```

**原因**: テストカバレッジが目標値に達していない

**解決方法**:

```bash
# カバレッジレポート生成
npm run test:coverage

# 未カバーのファイル確認
open coverage/lcov-report/index.html

# テスト追加後に再実行
npm test
```

## デバッグのヒント

### シェルスクリプトのデバッグ

```bash
# トレースモードで実行
bash -x script/import.sh

# 特定の関数だけトレース
set -x
function_name args
set +x

# エラー時に停止
set -e
```

### 環境変数の確認

```bash
# すべての環境変数を表示
env | sort

# 特定の変数を検索
env | grep REPO_PATH

# 変数が設定されているか確認
echo "${REPO_PATH:-not set}"
```

## サポート

問題が解決しない場合:

1. [Issues](https://github.com/keito4/config/issues)で既知の問題を検索
2. 新しいIssueを作成（以下を含める）:
   - OS とバージョン
   - エラーメッセージの全文
   - 再現手順
   - 期待される動作

````

### Step 5: README.mdの構造化改善（4時間）

```markdown
# README.md の目次追加

## 目次

- [概要](#概要)
- [特徴](#特徴)
- [ディレクトリ構造](#ディレクトリ構造)
- [前提条件](#前提条件)
- [クイックスタート](#クイックスタート)
- [使い方](#使い方)
  - [設定のインポート](#設定のインポート)
  - [設定のエクスポート](#設定のエクスポート)
- [開発](#開発)
  - [テスト](#テスト)
  - [リント](#リント)
  - [フォーマット](#フォーマット)
- [CI/CD](#cicd)
- [セキュリティ](#セキュリティ)
- [トラブルシューティング](#トラブルシューティング)
- [貢献](#貢献)
- [ライセンス](#ライセンス)
````

## タスクリスト

### Phase 1: シェルスクリプトのドキュメント（Week 1-2）

- [ ] script/lib/platform.sh に関数ドキュメント追加
- [ ] script/lib/devcontainer.sh に関数ドキュメント追加
- [ ] script/import.sh に関数ドキュメント追加
- [ ] script/export.sh に関数ドキュメント追加
- [ ] 複雑なロジックにインラインコメント追加

### Phase 2: ADRの作成（Week 3-4）

- [ ] docs/adr/ ディレクトリ作成
- [ ] ADRテンプレート作成
- [ ] ADR 0001: Zsh選択の理由
- [ ] ADR 0002: DevContainerベースイメージ
- [ ] ADR 0003: semantic-release設定
- [ ] ADR 0004: commitlintカスタムルール
- [ ] ADR 0005: クレデンシャルフィルタリング戦略
- [ ] ADR 0006: Claude設定の分離

### Phase 3: トラブルシューティング（Week 5）

- [ ] docs/TROUBLESHOOTING.md 作成
- [ ] よくある問題のリスト化
- [ ] 各問題の解決方法を記述
- [ ] デバッグのヒント追加

### Phase 4: README改善（Week 6）

- [ ] 目次の追加
- [ ] 各セクションへのアンカーリンク
- [ ] クイックスタートセクションの充実
- [ ] 前提条件の明確化

## 成功基準

- [ ] すべての公開関数にドキュメントが存在
- [ ] 複雑なロジックにコメントあり（複雑度 >5）
- [ ] 少なくとも6つのADRが作成済み
- [ ] トラブルシューティングガイドが完成
- [ ] READMEに目次とクイックスタートあり

## ROI計算

**投資**

- 関数ドキュメント: 12時間
- インラインコメント: 4時間
- ADR作成: 16時間
- トラブルシューティング: 8時間
- README改善: 4時間
- **合計**: 44時間 × $150/h = $6,600

**リターン**（定性的）

- オンボーディング時間: 50%削減 → 8時間/新メンバー
- デバッグ時間: 20%削減 → 4時間/月
- 意思決定の透明性向上: プライスレス

**定量的リターン**

- 新メンバー年間2人と仮定: 16時間節約
- 月次デバッグ削減: 48時間/年
- **年間節約**: 64時間 × $150 = $9,600
- **ROI**: 45% (初年度)、191% (2年累積)

## ドキュメント品質チェック

### レビューチェックリスト

```markdown
- [ ] 関数の目的が明確
- [ ] 引数と戻り値が説明されている
- [ ] 使用例が提供されている
- [ ] エラーケースが説明されている
- [ ] 前提条件が明記されている
```

## 関連Issue

- #005: シェルスクリプトのリファクタリング（新しい関数のドキュメントが必要）

## 参考リンク

- [Architecture Decision Records](https://adr.github.io/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Write the Docs](https://www.writethedocs.org/)
- [README Best Practices](https://github.com/jehna/readme-best-practices)
