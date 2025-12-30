# Issue #002: shellcheck静的解析の導入

## 優先度

🟠 **高 (Quick Win)**

## 現状

- **shellcheck**: 未導入
- **シェルスクリプト総行数**: 1,474行
- **スクリプトファイル数**: 15ファイル
- **静的解析**: なし ❌

## 問題の詳細

### リスク

- 構文エラーの見逃し
- 変数の未定義・未使用
- クォーティングの問題
- パス展開の問題
- POSIX互換性の問題

### 想定される問題頻度

- **四半期に1回**: 深刻なスクリプトエラー
- **調査時間**: 3-4時間
- **修正時間**: 2-3時間
- **ユーザー影響**: DevContainer起動失敗、import/export失敗など

### 年間コスト

```
問題発生: 4回/年 × 6時間/件 = 24時間
コスト: 24時間 × $150/h = $3,600
```

## 実装計画

### Step 1: DevContainerへの追加（30分）

```dockerfile
# .devcontainer/Dockerfile に追加
RUN apt-get update && apt-get install -y \
    shellcheck \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### Step 2: npm scriptの追加（15分）

```json
// package.json
{
  "scripts": {
    "shellcheck": "find script -name '*.sh' -exec shellcheck {} +",
    "shellcheck:fix": "find script -name '*.sh' -exec shellcheck --format=diff {} + | git apply"
  }
}
```

### Step 3: CIパイプラインへの統合（30分）

```yaml
# .github/workflows/ci.yml
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      # ... 既存のステップ ...

      - name: Install shellcheck
        run: sudo apt-get update && sudo apt-get install -y shellcheck

      - name: Check shell scripts
        run: npm run shellcheck
```

### Step 4: pre-commitフックの追加（15分）

```bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# 既存のフック
npm run lint
npm run format:check

# 新規: shellcheck
if command -v shellcheck >/dev/null 2>&1; then
  npm run shellcheck
fi
```

### Step 5: 既存スクリプトの修正（4時間）

検出される可能性のある問題の例：

```bash
# SC2086: 変数のクォーティング不足
# Before
cp -r $REPO_PATH/.claude ~/.claude

# After
cp -r "$REPO_PATH/.claude" ~/.claude

# SC2164: cdの失敗チェック不足
# Before
cd "$REPO_PATH"
npm install

# After
cd "$REPO_PATH" || exit 1
npm install

# SC2155: 変数宣言と代入の分離
# Before
local result=$(complex_command)

# After
local result
result=$(complex_command)
```

## タスクリスト

- [ ] DevContainerにshellcheckをインストール
- [ ] npm scriptに`shellcheck`を追加
- [ ] CIパイプラインに統合
- [ ] pre-commitフックに追加
- [ ] 既存スクリプトのshellcheck違反を修正
  - [ ] script/import.sh
  - [ ] script/export.sh
  - [ ] script/update-libraries.sh
  - [ ] script/credentials.sh
  - [ ] script/lib/platform.sh
  - [ ] script/lib/devcontainer.sh
  - [ ] その他のスクリプト
- [ ] .shellcheckrc設定ファイルの作成（必要に応じて）
- [ ] READMEにshellcheckバッジを追加

## 成功基準

- [ ] すべてのシェルスクリプトがshellcheckでエラー0件
- [ ] CIでshellcheckが自動実行される
- [ ] pre-commitでshellcheckが実行される
- [ ] 警告レベルの設定が適切（error, warning, info, style）

## shellcheck設定例

```bash
# .shellcheckrc
# 除外するルール（必要に応じて）
# SC1090: Can't follow non-constant source
# SC1091: Not following: file not included

# グローバル除外（必要最小限に）
# disable=SC1090,SC1091

# シェルの指定（デフォルトはbash）
shell=bash

# 外部ソースのチェック
external-sources=true
```

## ROI計算

**投資**

- DevContainer設定: 0.5時間
- npm/CI統合: 1時間
- pre-commit設定: 0.25時間
- 既存違反修正: 4時間
- **合計**: 5.75時間 × $150/h = $862.50

**リターン**

- 問題検出率向上: 80%
- 年間問題発生減少: 4回 → 0.8回
- **年間節約**: (4 - 0.8) × 6時間 × $150 = $2,880
- **ROI**: 234% (初年度)、568% (2年累積)

## 関連ファイル

### 修正対象スクリプト

- `script/import.sh`
- `script/export.sh`
- `script/update-libraries.sh`
- `script/commit_changes.sh`
- `script/credentials.sh`
- `script/brew-deps.sh`
- `script/version.sh`
- `script/setup-claude.sh`
- `script/install-claude-plugins.sh`
- `script/fix-container-plugins.sh`
- `script/post-create-plugins.sh`
- `script/verify-container-setup.sh`
- `script/lib/platform.sh`
- `script/lib/devcontainer.sh`
- `script/credentials/providers/op.sh`

### 設定ファイル

- `.devcontainer/Dockerfile`
- `package.json`
- `.github/workflows/ci.yml`
- `.husky/pre-commit`

## 参考リンク

- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [ShellCheck GitHub](https://github.com/koalaman/shellcheck)
- [Common ShellCheck Issues](https://github.com/koalaman/shellcheck/wiki/Checks)

## メモ

### よく見つかる問題

1. **SC2086**: クォーティング不足
2. **SC2164**: cdの失敗チェック不足
3. **SC2155**: 変数宣言と代入の分離
4. **SC2046**: クォートされていないコマンド置換
5. **SC2181**: $?の直接チェックより test -n を推奨

### ベストプラクティス

- すべての変数を二重引用符でクォート
- `cd` の後に `|| exit 1` を追加
- `set -euo pipefail` を使用（既に実装済み ✅）
- `shellcheck disable=SCXXXX` でルールごとに無効化可能
