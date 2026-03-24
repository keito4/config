#!/usr/bin/env bash
# Setup scheduled remote agents for Claude Code
# Usage: bash script/setup-scheduled-agents.sh

set -euo pipefail

# Claude CLI の存在確認
if ! command -v claude &> /dev/null; then
    echo "エラー: Claude CLI が見つかりません。先にインストールしてください。" >&2
    exit 1
fi

# リポジトリ URL を git remote から動的に取得（fallback あり）
REPO="$(git remote get-url origin 2>/dev/null | sed 's|git@github.com:|https://github.com/|; s|\.git$||')"
if [[ -z "$REPO" ]]; then
    REPO="https://github.com/keito4/config"
fi

echo "=== Scheduled Remote Agents セットアップ ==="
echo "リポジトリ: $REPO"
echo ""

# 既存スケジュール一覧を取得（冪等性確保）
existing_schedules="$(claude schedule list 2>/dev/null | grep -oP '(?<=Name: ).*' || true)"

# スケジュールが未登録の場合のみ作成するヘルパー関数
create_schedule_if_not_exists() {
  local name="$1"
  shift
  if echo "$existing_schedules" | grep -qF "$name"; then
    echo "  → スキップ（登録済み）: $name"
    return 0
  fi
  claude schedule create --name "$name" "$@" || {
    echo "  → 作成失敗（プラン上限の可能性）: $name" >&2
    return 0
  }
}

# 1. 依存関係の健全性レビュー（毎週月曜 10:00 JST = 1:00 UTC）
echo "[1/9] 依存関係健全性レビュー（毎週月曜 10:00 JST）"
create_schedule_if_not_exists "依存関係健全性レビュー" \
  --name "依存関係健全性レビュー" \
  --cron "0 1 * * 1" \
  --repo "$REPO" \
  --prompt "このリポジトリの依存関係の健全性をチェックしてください。
1. npm audit を実行し、脆弱性を確認
2. npm outdated で古いパッケージを特定
3. 非推奨パッケージがないか確認
4. Critical/High の脆弱性があればGitHub Issueを作成（ラベル: dependencies, security）
5. 結果のサマリをコミットログ形式で報告"
echo ""

# 2. config-base イメージ同期チェック（毎週水曜 10:00 JST = 1:00 UTC）
echo "[2/9] config-base同期チェック（毎週水曜 10:00 JST）"
create_schedule_if_not_exists "config-base同期チェック" \
  --cron "0 1 * * 3" \
  --repo "$REPO" \
  --prompt "config-baseイメージの同期状態を確認してください。
1. .devcontainer/Dockerfile のベースイメージタグを確認
2. ghcr.io/keito4/config-base:latest の最新ダイジェストと比較
3. 差分がある場合、更新PRを作成（ブランチ名: chore/update-config-base-image）
4. 差分がない場合は何もしない"
echo ""

# 3. コード複雑度トレンド監視（毎週金曜 10:00 JST = 1:00 UTC）
echo "[3/9] コード複雑度監視（毎週金曜 10:00 JST）"
create_schedule_if_not_exists "コード複雑度監視" \
  --cron "0 1 * * 5" \
  --repo "$REPO" \
  --prompt "リポジトリのコード複雑度を分析してください。
1. script/code-complexity-check.sh があれば実行
2. なければ、主要なJS/TSファイルの循環的複雑度を手動で分析
3. 複雑度が高い関数（10以上）をリストアップ
4. 前回と比較して悪化しているものがあればGitHub Issueを作成（ラベル: tech-debt）
5. 結果サマリを報告"
echo ""

# 4. テンプレート乖離チェック（毎月1日 10:00 JST = 1:00 UTC）
echo "[4/9] テンプレート乖離チェック（毎月1日 10:00 JST）"
create_schedule_if_not_exists "テンプレート乖離チェック" \
  --cron "0 1 1 * *" \
  --repo "$REPO" \
  --prompt "templates/ ディレクトリのテンプレートと実際のファイルの乖離を確認してください。
1. templates/github/ 配下のワークフローテンプレートと .github/workflows/ の差分を確認
2. templates/ 配下の設定テンプレートが最新のベストプラクティスに沿っているか確認
3. 乖離や改善点があればGitHub Issueを作成（ラベル: maintenance）
4. 結果サマリを報告"
echo ""

# 5. ドキュメント鮮度チェック（毎月15日 10:00 JST = 1:00 UTC）
echo "[5/9] ドキュメント鮮度チェック（毎月15日 10:00 JST）"
create_schedule_if_not_exists "ドキュメント鮮度チェック" \
  --cron "0 1 15 * *" \
  --repo "$REPO" \
  --prompt "ドキュメントの鮮度を確認してください。
1. README.md の内容が実際のプロジェクト構造・コマンドと一致しているか確認
2. CLAUDE.md のコマンド一覧・ワークフロー一覧が最新か確認
3. docs/adr/ のADRが実装と乖離していないか確認
4. 古くなっている箇所があれば修正PRを作成（ブランチ名: docs/update-stale-docs）
5. 軽微な場合はGitHub Issueのみ作成（ラベル: documentation）"
echo ""

# 6. CI失敗分析（毎日 10:00 JST = 1:00 UTC）
echo "[6/9] CI失敗分析（毎日 10:00 JST）"
create_schedule_if_not_exists "CI失敗分析" \
  --cron "0 1 * * *" \
  --repo "$REPO" \
  --prompt "過去24時間のCI失敗を分析してください。
1. gh run list --status failure --limit 20 で失敗したワークフローを取得
2. 失敗を根本原因ごとにグループ化（テスト失敗、lint、ビルドエラー、flaky test等）
3. 各グループに対して最小限の修正案を提示
4. flaky testが検出された場合はGitHub Issueを作成（ラベル: flaky-test, ci）
5. 繰り返し失敗しているワークフローがあれば優先度を上げて報告"
echo ""

# 7. 未テストパス検出（毎週木曜 10:00 JST = 1:00 UTC）
echo "[7/9] 未テストパス検出（毎週木曜 10:00 JST）"
create_schedule_if_not_exists "未テストパス検出" \
  --cron "0 1 * * 4" \
  --repo "$REPO" \
  --prompt "最近の変更からテストされていないコードパスを特定してください。
1. git log --since='7 days ago' --name-only で変更ファイルを取得
2. 変更されたJS/TSファイルに対応するテストファイルが存在するか確認
3. npm test -- --coverage を実行し、変更ファイルのカバレッジを確認
4. カバレッジ70%未満のファイルをリストアップ
5. 不足しているテストのドラフトPRを作成（ブランチ名: test/add-missing-coverage）"
echo ""

# 8. 新規Issueトリアージ（毎日 11:00 JST = 2:00 UTC）
echo "[8/9] 新規Issueトリアージ（毎日 11:00 JST）"
create_schedule_if_not_exists "新規Issueトリアージ" \
  --cron "0 2 * * *" \
  --repo "$REPO" \
  --prompt "未トリアージのIssueを整理してください。
1. gh issue list --label '' --state open でラベルなしのIssueを取得
2. Issue内容を分析し、適切なラベルを提案（bug, enhancement, documentation, maintenance等）
3. 優先度を判定（critical/high/medium/low）
4. 関連するファイルやコンポーネントを特定
5. gh issue edit でラベルを付与し、コメントで優先度と対応方針を記載"
echo ""

# 9. 週次リリースノート（毎週月曜 11:00 JST = 2:00 UTC）
echo "[9/9] 週次リリースノート（毎週月曜 11:00 JST）"
create_schedule_if_not_exists "週次リリースノート" \
  --cron "0 2 * * 1" \
  --repo "$REPO" \
  --prompt "先週マージされたPRから週次リリースノートを作成してください。
1. 今日の日付から7日前の日付を計算し、gh pr list --state merged で先週マージされたPRを取得（--limit 50 で十分な件数を確保）
2. PRをカテゴリ別に分類（feat, fix, chore, docs等）
3. 主要な変更点のハイライトとPRリンクを含むサマリを作成
4. リスクのある変更や破壊的変更があれば明示
5. GitHub Discussionsまたは新規Issueとしてリリースノートを投稿（ラベル: release-notes）"
echo ""

echo "=== セットアップ完了（全9エージェント） ==="
echo "管理画面: https://claude.ai/code/scheduled"
