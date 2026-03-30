#!/usr/bin/env python3
"""
PR作成後にGitHub Actions CIを監視するPostToolUseフック

gh pr create 成功後に自動的にCIの状態を監視し、結果を報告します。
CI完了まで待機（最大10分）し、失敗時は修正を促します。
"""
import sys
import json
import subprocess
import time
from common import (load_hook_input, parse_tool_context, is_bash_command,
                    is_help_command, extract_pr_url, print_header, print_footer, print_status)

data = load_hook_input()
tool_name, tool_input, tool_response = parse_tool_context(data)

if not is_bash_command(tool_name):
    sys.exit(0)

command = tool_input.get("command", "").strip()
if not command.startswith("gh pr create"):
    sys.exit(0)

if is_help_command(command):
    sys.exit(0)

stdout = tool_response.get("stdout", "")
stderr = tool_response.get("stderr", "")
combined_output = stdout + stderr

pr_info = extract_pr_url(combined_output)
if not pr_info:
    sys.exit(0)

pr_url, _, _, pr_number = pr_info

print_header(f"🔄 PR作成完了。CIステータスを監視中...\n📎 PR: {pr_url}")


def get_pr_checks(pr_number: str, timeout_seconds: int = 600):
    """PRのCIチェック状態を監視（最大10分）"""
    start_time = time.time()
    check_interval = 15  # 15秒ごとにチェック
    last_status = None

    while time.time() - start_time < timeout_seconds:
        try:
            result = subprocess.run(
                ["gh", "pr", "checks", pr_number, "--json", "name,state,conclusion"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode != 0:
                # チェックがまだ登録されていない場合は待機
                elapsed = int(time.time() - start_time)
                if elapsed < 30:
                    print(f"   ⏳ CIチェック待機中... ({elapsed}秒)", file=sys.stderr, flush=True)
                    time.sleep(check_interval)
                    continue
                return "no_checks", []

            checks = json.loads(result.stdout)
            if not checks:
                elapsed = int(time.time() - start_time)
                if elapsed < 30:
                    print(f"   ⏳ CIチェック待機中... ({elapsed}秒)", file=sys.stderr, flush=True)
                    time.sleep(check_interval)
                    continue
                return "no_checks", []

            # チェック状態を集計
            pending = [c for c in checks if c.get("state") == "PENDING"]
            in_progress = [c for c in checks if c.get("state") == "IN_PROGRESS"]
            completed = [c for c in checks if c.get("state") == "SUCCESS" or c.get("state") == "FAILURE" or c.get("state") == "SKIPPED"]
            failed = [c for c in checks if c.get("conclusion") == "FAILURE" or c.get("state") == "FAILURE"]

            total = len(checks)
            done = len(completed)

            # 状態が変わったときだけ表示
            current_status = f"{done}/{total}"
            if current_status != last_status:
                elapsed = int(time.time() - start_time)
                print(f"   ⏳ {elapsed}秒経過... ({done}/{total} 完了)", file=sys.stderr, flush=True)
                last_status = current_status

            # 全て完了した場合
            if done == total:
                if failed:
                    return "failure", failed
                return "success", checks

            time.sleep(check_interval)

        except Exception as e:
            print(f"⚠️  監視エラー: {e}", file=sys.stderr, flush=True)
            break

    return "timeout", []


# CI監視を実行
print("\n🔄 CI実行を監視中... (最大10分)", file=sys.stderr, flush=True)
conclusion, checks = get_pr_checks(pr_number)

if conclusion == "success":
    print("\n✅ 全CIチェック成功！", file=sys.stderr, flush=True)
elif conclusion == "failure":
    print("\n❌ CIチェック失敗", file=sys.stderr, flush=True)
    print("\n失敗したチェック:", file=sys.stderr, flush=True)
    for check in checks:
        print(f"   - {check.get('name', 'Unknown')}", file=sys.stderr, flush=True)
    print(f"\n詳細: gh pr checks {pr_number}", file=sys.stderr, flush=True)
    print("\n⚠️  CI修正が必要です。このブランチで修正してください。", file=sys.stderr, flush=True)
elif conclusion == "timeout":
    print("\n⏰ CI監視タイムアウト（まだ実行中）", file=sys.stderr, flush=True)
    print(f"   詳細: gh pr checks {pr_number} --watch", file=sys.stderr, flush=True)
elif conclusion == "no_checks":
    print("\n⚠️  CIチェックが見つかりません", file=sys.stderr, flush=True)
    print("   （CI未設定、またはワークフロー起動中の可能性があります）", file=sys.stderr, flush=True)

print_footer()

# PostToolUseフックは常に成功で終了（ブロックしない）
sys.exit(0)
