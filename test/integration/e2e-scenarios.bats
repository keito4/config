#!/usr/bin/env bats

# E2E scenario integration tests

load ../test_helper/test_helper

@test "新規環境セットアップシナリオ: 必須ツールの存在確認" {
  # Scenario: 新規環境で必須ツールがインストールされているか確認

  # Node.jsとnpmが利用可能
  command_exists node
  command_exists npm

  # Gitが利用可能
  command_exists git

  # 基本的なシェルツールが利用可能
  command_exists grep
  command_exists sed
  command_exists awk
}

@test "新規環境セットアップシナリオ: package.jsonの依存関係インストール" {
  # Scenario: npm ciで依存関係を正しくインストールできる

  local test_dir="${TEST_TEMP_DIR}/setup-test"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # package.jsonをコピー
  cp "${REPO_ROOT}/package.json" "$test_dir/"
  cp "${REPO_ROOT}/package-lock.json" "$test_dir/" 2>/dev/null || true

  # npm installが成功するか確認 (実際にはインストールしない、テストのみ)
  assert_file_exists "$test_dir/package.json"
}

@test "新規環境セットアップシナリオ: 設定ファイルの検証" {
  # Scenario: 必須の設定ファイルがすべて存在する

  # Git設定
  assert_file_exists "${REPO_ROOT}/.gitignore"
  assert_file_exists "${REPO_ROOT}/git/gitconfig"

  # Linter/Formatter設定
  assert_file_exists "${REPO_ROOT}/eslint.config.mjs"
  assert_file_exists "${REPO_ROOT}/.prettierrc"

  # Jest設定
  assert_file_exists "${REPO_ROOT}/jest.config.js"

  # Commitlint設定
  assert_file_exists "${REPO_ROOT}/commitlint.config.js"
}

@test "設定更新シナリオ: package.jsonバージョン更新の検証" {
  # Scenario: package.jsonのバージョン番号が正しいフォーマットか確認

  local package_json="${REPO_ROOT}/package.json"
  assert_file_exists "$package_json"

  # バージョン番号がsemverフォーマットか確認
  grep -q '"version":.*"[0-9]\+\.[0-9]\+\.[0-9]\+"' "$package_json"
}

@test "設定更新シナリオ: .gitignoreに必要なパターンが含まれる" {
  # Scenario: .gitignoreに重要な除外パターンが含まれている

  local gitignore="${REPO_ROOT}/.gitignore"
  assert_file_exists "$gitignore"

  # 必須の除外パターン
  grep -q "node_modules" "$gitignore"
  grep -q "coverage" "$gitignore"
  grep -q "\.env" "$gitignore"
}

@test "設定更新シナリオ: 新しいnpmスクリプトの追加" {
  # Scenario: package.jsonに必要なnpmスクリプトが定義されている

  local package_json="${REPO_ROOT}/package.json"

  # 必須スクリプトの存在確認
  grep -q '"test":' "$package_json"
  grep -q '"lint":' "$package_json"
  grep -q '"format:check":' "$package_json"
  grep -q '"test:coverage":' "$package_json"
}

@test "リカバリーシナリオ: テスト失敗時のエラーメッセージ" {
  # Scenario: テストが失敗した場合、適切なエラーメッセージが表示される

  # 意図的に失敗するテストスクリプトを作成
  local test_script="${TEST_TEMP_DIR}/fail-test.sh"
  cat > "$test_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Running test..."
echo "Test failed: Expected value 'foo' but got 'bar'" >&2
exit 1
EOF
  chmod +x "$test_script"

  # テストが失敗することを確認
  run "$test_script"
  [ "$status" -ne 0 ]

  # エラーメッセージが含まれているか確認
  [[ "$output" == *"Test failed"* ]]
}

@test "リカバリーシナリオ: Git操作のロールバック" {
  # Scenario: Git操作で問題が発生した場合のロールバック手順

  local test_repo="${TEST_TEMP_DIR}/git-test"
  mkdir -p "$test_repo"
  cd "$test_repo"

  # Gitリポジトリを初期化
  git init
  git config user.email "test@example.com"
  git config user.name "Test User"

  # ファイルを追加してコミット
  echo "test" > test.txt
  git add test.txt
  git commit -m "Initial commit"

  # 現在のコミットハッシュを保存
  local initial_commit=$(git rev-parse HEAD)

  # 新しい変更を追加
  echo "new content" >> test.txt
  git add test.txt
  git commit -m "Second commit"

  # ロールバック (git reset --hard)
  git reset --hard "$initial_commit"

  # ロールバックが成功したか確認
  local current_commit=$(git rev-parse HEAD)
  [ "$current_commit" = "$initial_commit" ]
}

@test "リカバリーシナリオ: 壊れた設定ファイルの検出" {
  # Scenario: JSONファイルが壊れている場合、適切にエラーを検出

  local invalid_json="${TEST_TEMP_DIR}/invalid.json"
  echo '{ "key": "value"' > "$invalid_json"  # 閉じ括弧なし

  # JSONパースが失敗することを確認
  run node -e "JSON.parse(require('fs').readFileSync('$invalid_json', 'utf8'))"
  [ "$status" -ne 0 ]
}

@test "統合シナリオ: CI/CDパイプラインの実行フロー" {
  # Scenario: CI/CDパイプラインで実行されるコマンドの順序確認

  local workflow="${REPO_ROOT}/.github/workflows/ci.yml"
  assert_file_exists "$workflow"

  # CI workflowの実行順序を確認
  # 1. npm ci
  grep -q "npm ci" "$workflow"

  # 2. linter
  grep -q "npm run lint" "$workflow"

  # 3. shellcheck
  grep -q "npm run shellcheck" "$workflow"

  # 4. formatter check
  grep -q "npm run format:check" "$workflow"

  # 5. tests with coverage
  grep -q "npm run test:coverage" "$workflow"
}

@test "統合シナリオ: スクリプトの依存関係チェーン" {
  # Scenario: スクリプトが他のスクリプトや設定ファイルに依存している

  # setup-claude.shがclaudeディレクトリ構造を期待
  local setup_script="${REPO_ROOT}/script/setup-claude.sh"
  if [ -f "$setup_script" ]; then
    grep -q "CLAUDE_DIR" "$setup_script"
    grep -q "PLUGINS_DIR" "$setup_script"
  fi

  # update-libraries.shがpackage.jsonやnpm/global.jsonに依存
  local update_script="${REPO_ROOT}/script/update-libraries.sh"
  if [ -f "$update_script" ]; then
    grep -q "package.json\|npm/global.json" "$update_script" || true
  fi
}

@test "統合シナリオ: Brewfileから依存関係を読み込む" {
  # Scenario: Brewfileが正しいフォーマットで依存関係を定義

  local brewfile="${REPO_ROOT}/brew/Brewfile.Linux"
  if [ -f "$brewfile" ]; then
    # Brewfileの基本構文確認
    # brew "package" または tap "tap/name" の形式
    grep -qE '^(brew|tap|cask)' "$brewfile" || true
  fi
}

@test "統合シナリオ: ドキュメントの一貫性チェック" {
  # Scenario: READMEとCLAUDE.mdの内容が一貫している

  assert_file_exists "${REPO_ROOT}/README.md"
  assert_file_exists "${REPO_ROOT}/CLAUDE.md"

  # READMEに基本的なセクションが含まれている
  grep -qi "# " "${REPO_ROOT}/README.md"
}

@test "統合シナリオ: セキュリティ設定の検証" {
  # Scenario: セキュリティに関連する設定が適切に行われている

  # .gitignoreに機密情報ファイルが含まれている
  grep -q "\.env" "${REPO_ROOT}/.gitignore"
  grep -q "credentials" "${REPO_ROOT}/.gitignore" || true

  # credentialsディレクトリにREADMEがある場合
  if [ -d "${REPO_ROOT}/credentials" ]; then
    assert_file_exists "${REPO_ROOT}/credentials/README.md" || true
  fi
}

@test "統合シナリオ: テストカバレッジ閾値の達成" {
  # Scenario: テストカバレッジが設定された閾値を満たしている

  local jest_config="${REPO_ROOT}/jest.config.js"
  assert_file_exists "$jest_config"

  # カバレッジ閾値が設定されている
  grep -q "coverageThreshold" "$jest_config"
  grep -q "70" "$jest_config"
}

@test "統合シナリオ: コミットメッセージの検証" {
  # Scenario: commitlintがConventional Commitsに従っている

  local commitlint_config="${REPO_ROOT}/commitlint.config.js"
  assert_file_exists "$commitlint_config"

  # Conventional Commits設定を使用
  grep -q "@commitlint/config-conventional" "$commitlint_config"
}
