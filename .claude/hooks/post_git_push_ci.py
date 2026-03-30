#!/usr/bin/env python3
"""
git push後にGitHub Actions CIを監視するPostToolUseフック

git push 成功後に自動的にCIの状態を確認し、結果を報告します。
"""
import sys
import json
import subprocess
import re
import time
from common import (load_hook_input, parse_tool_context, is_bash_command,
                    print_header, print_footer, print_status)

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


def get_current_branch():
    """現在のブランチ名を取得"""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.stdout.strip()
    except Exception:
        return None


def get_latest_run():
    """最新のworkflow runを取得"""
    try:
        branch = get_current_branch()
        if not branch:
            return None

        # 少し待ってからCIの状態を確認（ワークフロー起動に時間がかかる場合があるため）
        time.sleep(3)

        result = subprocess.run(
            ["gh", "run", "list", "--branch", branch, "--limit", "1", "--json", "databaseId,status,conclusion,name,workflowName,headSha,createdAt"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode != 0:
            return None

        runs = json.loads(result.stdout)
        if runs:
            return runs[0]
        return None

    except Exception as e:
        print(f"⚠️  CI状態取得エラー: {e}", file=sys.stderr, flush=True)
        return None


def watch_ci_run(run_id, timeout_seconds=300):
    """CIの実行を監視（最大5分）"""
    print(f"\n🔄 CI実行を監視中... (最大{timeout_seconds // 60}分)", file=sys.stderr, flush=True)

    start_time = time.time()
    check_interval = 15  # 15秒ごとにチェック

    while time.time() - start_time < timeout_seconds:
        try:
            result = subprocess.run(
                ["gh", "run", "view", str(run_id), "--json", "status,conclusion,jobs"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode != 0:
                break

            run_data = json.loads(result.stdout)
            status = run_data.get("status", "")
            conclusion = run_data.get("conclusion", "")

            if status == "completed":
                return conclusion, run_data.get("jobs", [])

            # 進行中の場合は待機
            elapsed = int(time.time() - start_time)
            print(f"   ⏳ {elapsed}秒経過... (status: {status})", file=sys.stderr, flush=True)
            time.sleep(check_interval)

        except Exception as e:
            print(f"⚠️  監視エラー: {e}", file=sys.stderr, flush=True)
            break

    return "timeout", []


# メイン処理
run = get_latest_run()

if not run:
    print("⚠️  GitHub Actions ワークフローが見つかりません", file=sys.stderr, flush=True)
    print("   （CI未設定、またはpush直後でまだ起動していない可能性があります）", file=sys.stderr, flush=True)
    sys.exit(0)

run_id = run.get("databaseId")
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
