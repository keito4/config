#!/usr/bin/env python3
"""
git push後にGitHub Actions CIを監視するPostToolUseフック

git push 成功後に自動的にCIの状態を確認し、結果を報告します。
"""
import sys
import re
from common import (load_hook_input, parse_tool_context, is_bash_command,
                    get_latest_run, watch_ci_run, print_header, print_footer)

data = load_hook_input()
tool_name, tool_input, tool_response = parse_tool_context(data)

if not is_bash_command(tool_name):
    sys.exit(0)

command = tool_input.get("command", "").strip()
if not command.startswith("git push"):
    sys.exit(0)

if "--help" in command or "-h" in command or "--dry-run" in command or "-n" in command:
    sys.exit(0)

# ツール実行が成功したかチェック
stdout = tool_response.get("stdout", "")
stderr = tool_response.get("stderr", "")
combined_output = stdout + stderr

# push成功のパターン（新しいブランチ or 既存ブランチへのpush）
success_patterns = [
    r"\[new branch\]",
    r"\.\..*->",  # abc123..def456 main -> main
    r"set up to track",
    r"Everything up-to-date"
]

# エラーパターン
error_patterns = [
    r"error:",
    r"fatal:",
    r"rejected"
]

# エラーがあればスキップ
for pattern in error_patterns:
    if re.search(pattern, combined_output, re.IGNORECASE):
        sys.exit(0)

# 成功パターンがなければスキップ
is_success = any(re.search(p, combined_output) for p in success_patterns)
if not is_success:
    sys.exit(0)

print_header("🚀 Push完了。GitHub Actions CIを確認中...")


# メイン処理
run = get_latest_run()

if not run:
    print("⚠️  GitHub Actions ワークフローが見つかりません", file=sys.stderr, flush=True)
    print("   （CI未設定、またはpush直後でまだ起動していない可能性があります）", file=sys.stderr, flush=True)
    sys.exit(0)

run_id = run.get("databaseId")
if run_id is None:
    print("⚠️  Run ID が取得できませんでした", file=sys.stderr, flush=True)
    sys.exit(0)
workflow_name = run.get("workflowName", run.get("name", "Unknown"))
status = run.get("status", "")
conclusion = run.get("conclusion", "")

print(f"\n📋 ワークフロー: {workflow_name}", file=sys.stderr, flush=True)
print(f"   Run ID: {run_id}", file=sys.stderr, flush=True)
print(f"   Status: {status}", file=sys.stderr, flush=True)

if status == "completed":
    # 既に完了している場合
    if conclusion == "success":
        print("\n✅ CI成功！", file=sys.stderr, flush=True)
    elif conclusion == "failure":
        print("\n❌ CI失敗", file=sys.stderr, flush=True)
        print(f"   詳細: gh run view {run_id}", file=sys.stderr, flush=True)
    else:
        print(f"\n⚠️  CI結果: {conclusion}", file=sys.stderr, flush=True)
else:
    # 実行中の場合は監視
    conclusion, jobs = watch_ci_run(run_id)

    if conclusion == "success":
        print("\n✅ CI成功！", file=sys.stderr, flush=True)
    elif conclusion == "failure":
        print("\n❌ CI失敗", file=sys.stderr, flush=True)
        # 失敗したジョブを表示
        failed_jobs = [j for j in jobs if j.get("conclusion") == "failure"]
        if failed_jobs:
            print("\n失敗したジョブ:", file=sys.stderr, flush=True)
            for job in failed_jobs:
                print(f"   - {job.get('name', 'Unknown')}", file=sys.stderr, flush=True)
        print(f"\n   詳細: gh run view {run_id}", file=sys.stderr, flush=True)
    elif conclusion == "timeout":
        print("\n⏰ CI監視タイムアウト（まだ実行中）", file=sys.stderr, flush=True)
        print(f"   詳細: gh run view {run_id} --watch", file=sys.stderr, flush=True)
    else:
        print(f"\n⚠️  CI結果: {conclusion}", file=sys.stderr, flush=True)

print_footer()

# PostToolUseフックは常に成功で終了（ブロックしない）
sys.exit(0)
