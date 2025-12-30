# Issue #004: シェルスクリプトの統合テスト実装

## 優先度

🟠 **高**

## 現状

- **統合テストフレームワーク**: 未導入
- **シェルスクリプト総行数**: 1,474行
- **手動テスト時間**: 2-3時間/変更
- **テストカバレッジ**: 0%

## 問題の詳細

### 未テストの重要スクリプト

1. `script/import.sh` (130行) - 環境セットアップ
2. `script/export.sh` (105行) - 設定エクスポート
3. `script/update-libraries.sh` (52行) - 依存関係更新
4. `script/credentials.sh` - 認証情報管理
5. `script/lib/platform.sh` - プラットフォーム抽象化
6. `script/lib/devcontainer.sh` - DevContainer統合

### テストが必要なシナリオ

- プラットフォーム検出（Linux, macOS）
- ファイル存在チェック
- ディレクトリ作成
- 設定ファイルのコピー
- エラーハンドリング
- 環境変数の処理

## 実装計画

### Step 1: Batsフレームワークのセットアップ（2時間）

```bash
# 1. batsと関連ツールのインストール
npm install --save-dev \
  bats \
  @bats/bats-core \
  @bats/bats-support \
  @bats/bats-assert

# 2. テストディレクトリの作成
mkdir -p test/integration
mkdir -p test/test_helper

# 3. test_helperのセットアップ
# test/test_helper/setup.bash
setup_test_repo() {
  export TEST_REPO_PATH="$(mktemp -d)"
  export REPO_PATH="$TEST_REPO_PATH"

  # 必要なディレクトリ構造を作成
  mkdir -p "$REPO_PATH"/{.claude,brew,git,npm,dot,script/lib}
}

cleanup_test_repo() {
  if [[ -n "$TEST_REPO_PATH" ]] && [[ -d "$TEST_REPO_PATH" ]]; then
    rm -rf "$TEST_REPO_PATH"
  fi
}
```

### Step 2: platform.shのテスト（4時間）

```bash
# test/integration/platform.bats
#!/usr/bin/env bats

load '../test_helper/setup'

setup() {
  source script/lib/platform.sh
}

@test "platform::detect_os detects Linux" {
  OSTYPE="linux-gnu"
  run platform::detect_os
  assert_success
  assert_output "linux"
}

@test "platform::detect_os detects macOS" {
  OSTYPE="darwin22"
  run platform::detect_os
  assert_success
  assert_output "darwin"
}

@test "platform::detect_os handles unknown OS" {
  OSTYPE="unknown"
  run platform::detect_os
  assert_failure
  assert_output --partial "Unsupported OS"
}

@test "platform::run_task executes platform-specific function" {
  # モック関数の定義
  test_task_linux() {
    echo "linux task"
  }

  test_task_darwin() {
    echo "darwin task"
  }

  OSTYPE="linux-gnu"
  run platform::run_task test_task
  assert_success
  assert_output "linux task"
}

@test "platform::assert_supported passes on supported platforms" {
  OSTYPE="darwin22"
  run platform::assert_supported
  assert_success
}
```

### Step 3: import.shのテスト（8時間）

```bash
# test/integration/import.bats
#!/usr/bin/env bats

load '../test_helper/setup'

setup() {
  setup_test_repo

  # モックファイルの作成
  echo '{"test": true}' > "$REPO_PATH/.claude/settings.json"
  mkdir -p "$REPO_PATH/.claude/commands"
  echo "test command" > "$REPO_PATH/.claude/commands/test.md"

  mkdir -p "$REPO_PATH/git"
  echo "[user]" > "$REPO_PATH/git/gitconfig"
}

teardown() {
  cleanup_test_repo
}

@test "import.sh creates .claude directory" {
  run bash script/import.sh
  assert_success
  [ -d "$HOME/.claude" ]
}

@test "import.sh copies settings.json correctly" {
  run bash script/import.sh
  assert_success
  [ -f "$HOME/.claude/settings.json" ]

  # 内容確認
  grep -q '"test": true' "$HOME/.claude/settings.json"
}

@test "import.sh copies commands directory" {
  run bash script/import.sh
  assert_success
  [ -d "$HOME/.claude/commands" ]
  [ -f "$HOME/.claude/commands/test.md" ]
}

@test "import.sh handles missing REPO_PATH" {
  unset REPO_PATH
  run bash script/import.sh
  assert_success
}

@test "import.sh sets correct file permissions" {
  echo "secret" > "$REPO_PATH/.zsh/configs/pre/.env.secret"

  run bash script/import.sh
  assert_success

  # .env.secretのパーミッションが600であることを確認
  if [ -f "$HOME/.zsh/configs/pre/.env.secret" ]; then
    perms=$(stat -c "%a" "$HOME/.zsh/configs/pre/.env.secret" 2>/dev/null || stat -f "%A" "$HOME/.zsh/configs/pre/.env.secret")
    [ "$perms" = "600" ]
  fi
}

@test "import.sh in DevContainer mode sets NONINTERACTIVE" {
  export PLATFORM_IN_DEVCONTAINER=true

  run bash script/import.sh
  assert_success

  # NONINTERACTIVE=1が設定されていることを確認（間接的）
  # Oh My Zshインストールスクリプトが非対話モードで実行されたか
}

@test "import.sh warns about missing personal info in gitconfig" {
  run bash script/import.sh
  assert_success
  assert_output --partial "個人情報がコメントアウトされています"
}
```

### Step 4: export.shのテスト（8時間）

```bash
# test/integration/export.bats
#!/usr/bin/env bats

load '../test_helper/setup'

setup() {
  setup_test_repo

  # ホームディレクトリに設定をセットアップ
  mkdir -p "$HOME/.claude"
  echo '{"exported": true}' > "$HOME/.claude/settings.json"

  mkdir -p "$HOME/.zsh"
  echo "export NPM_TOKEN=secret123" > "$HOME/.zshrc"
  echo "export PATH=/usr/local/bin" >> "$HOME/.zshrc"
}

teardown() {
  cleanup_test_repo
  rm -rf "$HOME/.claude/settings.json" "$HOME/.zshrc" 2>/dev/null || true
}

@test "export.sh creates necessary directories" {
  run bash script/export.sh
  assert_success
  [ -d "$REPO_PATH/.claude" ]
  [ -d "$REPO_PATH/git" ]
  [ -d "$REPO_PATH/npm" ]
}

@test "export.sh exports Claude settings" {
  run bash script/export.sh
  assert_success
  [ -f "$REPO_PATH/.claude/settings.json" ]
  grep -q '"exported": true' "$REPO_PATH/.claude/settings.json"
}

@test "export.sh filters credentials from .zshrc" {
  run bash script/export.sh
  assert_success

  # .zshrcがエクスポートされている
  [ -f "$REPO_PATH/dot/.zshrc" ]

  # NPM_TOKENが含まれていない
  ! grep -q "NPM_TOKEN" "$REPO_PATH/dot/.zshrc"

  # 通常の環境変数は残っている
  grep -q "PATH" "$REPO_PATH/dot/.zshrc"
}

@test "export.sh filters personal info from gitconfig" {
  echo "[user]" > "$HOME/.gitconfig"
  echo "  name = John Doe" >> "$HOME/.gitconfig"
  echo "  email = john@example.com" >> "$HOME/.gitconfig"
  echo "[core]" >> "$HOME/.gitconfig"
  echo "  editor = vim" >> "$HOME/.gitconfig"

  run bash script/export.sh
  assert_success

  # gitconfigがエクスポートされている
  [ -f "$REPO_PATH/git/gitconfig" ]

  # 個人情報がコメントアウトされている
  grep -q "# name =" "$REPO_PATH/git/gitconfig"
  grep -q "# email =" "$REPO_PATH/git/gitconfig"

  # 通常の設定は残っている
  grep -q "editor = vim" "$REPO_PATH/git/gitconfig"
}

@test "export.sh outputs success message" {
  run bash script/export.sh
  assert_success
  assert_output --partial "gitconfig exported"
}
```

### Step 5: E2Eラウンドトリップテスト（4時間）

```bash
# test/integration/roundtrip.bats
#!/usr/bin/env bats

load '../test_helper/setup'

setup() {
  setup_test_repo

  # 初期設定をセットアップ
  mkdir -p "$HOME/.claude/commands"
  echo '{"version": "1.0"}' > "$HOME/.claude/settings.json"
  echo "test command" > "$HOME/.claude/commands/test.md"
}

teardown() {
  cleanup_test_repo
}

@test "export → import roundtrip preserves configuration" {
  # 1. エクスポート
  run bash script/export.sh
  assert_success

  # 2. エクスポートされたファイルの確認
  [ -f "$REPO_PATH/.claude/settings.json" ]
  [ -f "$REPO_PATH/.claude/commands/test.md" ]

  # 3. ホームディレクトリをクリア
  rm -rf "$HOME/.claude"

  # 4. インポート
  run bash script/import.sh
  assert_success

  # 5. 復元確認
  [ -f "$HOME/.claude/settings.json" ]
  [ -f "$HOME/.claude/commands/test.md" ]

  # 6. 内容確認
  grep -q '"version": "1.0"' "$HOME/.claude/settings.json"
  grep -q "test command" "$HOME/.claude/commands/test.md"
}

@test "export does not include local-only files" {
  # ローカル専用ファイルを作成
  echo '{"local": true}' > "$HOME/.claude/settings.local.json"

  run bash script/export.sh
  assert_success

  # settings.local.jsonはエクスポートされない
  [ ! -f "$REPO_PATH/.claude/settings.local.json" ]

  # settings.jsonはエクスポートされる
  [ -f "$REPO_PATH/.claude/settings.json" ]
}
```

### Step 6: CI統合（2時間）

```yaml
# .github/workflows/ci.yml に追加
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      # ... 既存のステップ ...

      - name: Install Bats
        run: npm install

      - name: Run integration tests
        run: npm run test:integration
```

```json
// package.json に追加
{
  "scripts": {
    "test:integration": "bats test/integration/*.bats",
    "test:integration:verbose": "bats --tap test/integration/*.bats"
  }
}
```

## タスクリスト

- [ ] Batsフレームワークのインストール
- [ ] テストヘルパーの作成
- [ ] platform.shのテスト実装
- [ ] devcontainer.shのテスト実装
- [ ] import.shのテスト実装
  - [ ] 基本的なファイルコピー
  - [ ] Claude設定の処理
  - [ ] Git設定の処理
  - [ ] エラーハンドリング
  - [ ] DevContainerモード
- [ ] export.shのテスト実装
  - [ ] 基本的なエクスポート
  - [ ] クレデンシャルフィルタリング
  - [ ] 個人情報フィルタリング
  - [ ] ローカル専用ファイル除外
- [ ] update-libraries.shのテスト実装
- [ ] E2Eラウンドトリップテスト
- [ ] CIパイプラインに統合
- [ ] テストドキュメントの作成

## 成功基準

- [ ] 重要スクリプトのカバレッジ 60%以上
- [ ] すべてのテストがCI/CDで自動実行
- [ ] テスト実行時間 < 5分
- [ ] 環境依存のテスト失敗なし

## ROI計算

**投資**

- Batsセットアップ: 2時間
- platform.shテスト: 4時間
- import.shテスト: 8時間
- export.shテスト: 8時間
- E2Eテスト: 4時間
- CI統合: 2時間
- **合計**: 28時間 × $150/h = $4,200

**リターン**

- 手動テスト削減: 2.5時間/変更 → 0.5時間/変更
- 月次変更頻度: 4回
- **月次節約**: 2時間 × 4回 = 8時間
- **年間節約**: 96時間 × $150 = $14,400
- **ROI**: 243% (初年度)、586% (2年累積)

## 関連ファイル

### テスト対象

- `script/lib/platform.sh`
- `script/lib/devcontainer.sh`
- `script/import.sh`
- `script/export.sh`
- `script/update-libraries.sh`

### テストファイル（新規作成）

- `test/integration/platform.bats`
- `test/integration/devcontainer.bats`
- `test/integration/import.bats`
- `test/integration/export.bats`
- `test/integration/update-libraries.bats`
- `test/integration/roundtrip.bats`
- `test/test_helper/setup.bash`

### 設定ファイル

- `package.json` - bats依存関係とスクリプト
- `.github/workflows/ci.yml` - CI統合

## テストベストプラクティス

### 1. テストの独立性

```bash
setup() {
  # 各テストで新しい一時ディレクトリを使用
  export TEST_REPO_PATH="$(mktemp -d)"
}

teardown() {
  # テスト後のクリーンアップ
  rm -rf "$TEST_REPO_PATH"
}
```

### 2. モックの使用

```bash
# 外部コマンドのモック
brew() {
  echo "mock brew command"
  return 0
}
export -f brew
```

### 3. アサーションの明確化

```bash
# 良い例
assert_success
assert_output "expected output"

# 悪い例
[ $status -eq 0 ]
```

## 参考リンク

- [Bats Documentation](https://bats-core.readthedocs.io/)
- [bats-support](https://github.com/bats-core/bats-support)
- [bats-assert](https://github.com/bats-core/bats-assert)
- [Testing Shell Scripts](https://www.shellcheck.net/wiki/SC2086)
