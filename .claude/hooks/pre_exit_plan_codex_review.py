#!/usr/bin/env python3
"""
ExitPlanMode前にプランをCodexでレビューするPreToolUseフック

プラン作成後、ExitPlanMode実行前に自動的にCodexによるプランレビューを実行します。
問題がある場合はブロックして修正を促します。
"""
import sys
import json
import subprocess
import shutil
import os
import glob

# Read input from Claude
data = json.load(sys.stdin)

tool_name = data.get("tool_name", "")

# ExitPlanMode でない場合はスキップ
if tool_name != "ExitPlanMode":
    sys.exit(0)

# Codex CLIがインストールされているか確認
if not shutil.which("codex"):
    print("⚠️  Codex CLIがインストールされていません。スキップします。", file=sys.stderr)
    sys.exit(0)

# プランファイルを検出
plan_dir = os.path.expanduser("~/.claude/plans")
plan_files = []

if os.path.isdir(plan_dir):
    # 最新のプランファイルを取得
    plan_files = sorted(
        glob.glob(os.path.join(plan_dir, "*.md")),
        key=os.path.getmtime,
        reverse=True
    )

if not plan_files:
    print("⚠️  プランファイルが見つかりません。スキップします。", file=sys.stderr)
    sys.exit(0)

latest_plan = plan_files[0]
plan_name = os.path.basename(latest_plan)

# プランファイルの内容を読み込む
try:
    with open(latest_plan, 'r', encoding='utf-8') as f:
        plan_content = f.read()
except Exception as e:
    print(f"⚠️  プランファイル読み込みエラー: {e}", file=sys.stderr)
    sys.exit(0)

# Codexレビューを実行
print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print(f"🔍 プラン '{plan_name}' をCodexでレビュー中...", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print("", file=sys.stderr)

codex_prompt = f"""You are reviewing an implementation plan before it is approved for execution.
Analyze the following plan and provide feedback on:

1. **Completeness**: Are all requirements addressed? Are there missing steps?
2. **Technical Feasibility**: Is the approach technically sound? Are there better alternatives?
3. **Risks**: What potential issues might arise during implementation?
4. **Dependencies**: Are all dependencies and prerequisites identified?
5. **Order of Operations**: Is the implementation order logical and efficient?

After your analysis, provide:
- A list of issues found (if any)
- Recommendations for improvement
- An overall verdict: 'plan is ready' or 'plan needs revision'
- A confidence score between 0 and 1

## Plan Content:

{plan_content}
"""

codex_command = [
    "codex", "exec",
    "--sandbox", "read-only",
    codex_prompt
]

review_success = False

try:
    result = subprocess.run(
        codex_command,
        cwd=os.getcwd(),
        capture_output=True,
        text=True,
        timeout=600  # 10分タイムアウト
    )

    print("## Codex Plan Review Results", file=sys.stderr)
    print("", file=sys.stderr)

    if result.stdout:
        print(result.stdout, file=sys.stderr)
        output = result.stdout.lower()

        # verdictが "plan needs revision" の場合はブロック
        if "plan needs revision" in output:
            print("", file=sys.stderr)
            print("=" * 60, file=sys.stderr)
            print("❌ プランに修正が必要です。上記の指摘を確認してください。", file=sys.stderr)
            print("=" * 60, file=sys.stderr)
            sys.exit(2)

        # verdictが "plan is ready" の場合のみ成功
        if "plan is ready" in output:
            review_success = True

    # Codex実行エラーの場合
    if result.returncode != 0:
        print(f"⚠️  Codex実行エラー (exit code: {result.returncode})", file=sys.stderr)
        if result.stderr:
            print(f"    {result.stderr[:500]}", file=sys.stderr)

except subprocess.TimeoutExpired:
    print("⚠️  Codexレビューがタイムアウトしました（10分）", file=sys.stderr)
    # タイムアウトの場合は続行を許可（ブロックしすぎを避ける）

except Exception as e:
    print(f"⚠️  Codexレビュー実行エラー: {e}", file=sys.stderr)
    # エラーの場合は続行を許可

# 結果の表示
print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)
if review_success:
    print("✅ Codexプランレビュー完了 - 問題なし", file=sys.stderr)
else:
    print("⚠️  Codexプランレビュー完了 - 明確な承認なし（続行を許可）", file=sys.stderr)
print("=" * 60, file=sys.stderr)

sys.exit(0)
