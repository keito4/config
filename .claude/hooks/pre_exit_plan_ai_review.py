#!/usr/bin/env python3
"""
ExitPlanMode前にプランをAIでレビューするPreToolUseフック

プラン作成後、ExitPlanMode実行前に自動的にCodexとGeminiによるプランレビューを実行します。
いずれかのAIが「plan needs revision」と判定した場合はブロックして修正を促します。
"""
import sys
import json
import subprocess
import shutil
import os
import glob
from common import load_hook_input, print_header, print_footer, print_section, print_status

data = load_hook_input()
tool_name = data.get("tool_name", "")

# ExitPlanMode でない場合はスキップ
if tool_name != "ExitPlanMode":
    sys.exit(0)

# 利用可能なAIツールを確認
has_codex = shutil.which("codex") is not None
has_gemini = shutil.which("gemini") is not None

if not has_codex and not has_gemini:
    print("⚠️  AIレビューツール（Codex/Gemini）がインストールされていません。スキップします。", file=sys.stderr, flush=True)
    sys.exit(0)

# プランファイルを検出
plan_dir = os.path.expanduser("~/.claude/plans")
plan_files = []

if os.path.isdir(plan_dir):
    plan_files = sorted(
        glob.glob(os.path.join(plan_dir, "*.md")),
        key=os.path.getmtime,
        reverse=True
    )

if not plan_files:
    print("⚠️  プランファイルが見つかりません。スキップします。", file=sys.stderr, flush=True)
    sys.exit(0)

latest_plan = plan_files[0]
plan_name = os.path.basename(latest_plan)

# プランファイルの内容を読み込む
try:
    with open(latest_plan, 'r', encoding='utf-8') as f:
        plan_content = f.read()
except Exception as e:
    print(f"⚠️  プランファイル読み込みエラー: {e}", file=sys.stderr, flush=True)
    sys.exit(0)

print_header(f"🔍 プラン '{plan_name}' をAIでレビュー中...")

# レビュープロンプト
review_prompt = f"""You are reviewing a software implementation plan before it is approved for execution.

Focus your review on **code-level technical correctness**. Evaluate:

1. **Completeness**: Are the code changes well-identified? Are critical files and functions listed?
2. **Technical Feasibility**: Is the approach technically sound? Will the changes compile and pass tests?
3. **Risks**: Are there code-level risks (broken imports, missing references, type errors)?
4. **Dependencies**: Are code-level dependencies between changes identified?
5. **Verification**: Are there adequate automated checks (type-check, lint, test, build)?

**Important guidelines for your review:**
- Focus on whether the plan will produce correct, working code changes
- Do NOT flag operational/organizational concerns (access logs, stakeholder communication, Postman collections, monitoring dashboards, team notifications) as blocking issues
- Do NOT require steps that are outside the scope of code changes (e.g., checking external services, reviewing analytics, contacting team members)
- If the plan includes comprehensive automated verification (type-check, lint, test, build), that is sufficient for validating correctness
- Only mark 'plan needs revision' for genuine technical flaws that would cause the implementation to fail
- Mark 'plan is ready' if the code changes are well-identified, the approach is sound, and verification steps are adequate

After your analysis, provide:
- A list of **code-level** issues found (if any)
- Recommendations for improvement (optional, non-blocking suggestions are fine)
- An overall verdict: 'plan is ready' or 'plan needs revision'
- A confidence score between 0 and 1

## Plan Content:

{plan_content}
"""

# レビュー結果を格納
review_results = {
    "codex": {"success": False, "needs_revision": False, "ready": False},
    "gemini": {"success": False, "needs_revision": False, "ready": False}
}


def run_codex_review():
    """Codexによるプランレビューを実行"""
    print_section("🤖 Codex Plan Review")

    codex_command = [
        "codex", "exec",
        "--sandbox", "read-only",
        review_prompt
    ]

    try:
        result = subprocess.run(
            codex_command,
            cwd=os.getcwd(),
            capture_output=True,
            text=True,
            timeout=600
        )

        if result.stdout:
            print(result.stdout, file=sys.stderr, flush=True)
            output = result.stdout.lower()

            review_results["codex"]["success"] = True
            if "plan needs revision" in output:
                review_results["codex"]["needs_revision"] = True
            if "plan is ready" in output:
                review_results["codex"]["ready"] = True

        if result.returncode != 0:
            print(f"⚠️  Codex実行エラー (exit code: {result.returncode})", file=sys.stderr, flush=True)

    except subprocess.TimeoutExpired:
        print("⚠️  Codexレビューがタイムアウトしました（10分）", file=sys.stderr, flush=True)
    except Exception as e:
        print(f"⚠️  Codexレビュー実行エラー: {e}", file=sys.stderr, flush=True)


def run_gemini_review():
    """Geminiによるプランレビューを実行"""
    print_section("✨ Gemini Plan Review")

    gemini_command = [
        "gemini",
        "-p", review_prompt
    ]

    try:
        result = subprocess.run(
            gemini_command,
            cwd=os.getcwd(),
            capture_output=True,
            text=True,
            timeout=600
        )

        if result.stdout:
            print(result.stdout, file=sys.stderr, flush=True)
            output = result.stdout.lower()

            review_results["gemini"]["success"] = True
            if "plan needs revision" in output:
                review_results["gemini"]["needs_revision"] = True
            if "plan is ready" in output:
                review_results["gemini"]["ready"] = True

        if result.returncode != 0:
            print(f"⚠️  Gemini実行エラー (exit code: {result.returncode})", file=sys.stderr, flush=True)

    except subprocess.TimeoutExpired:
        print("⚠️  Geminiレビューがタイムアウトしました（10分）", file=sys.stderr, flush=True)
    except Exception as e:
        print(f"⚠️  Geminiレビュー実行エラー: {e}", file=sys.stderr, flush=True)


# 利用可能なツールでレビューを実行
if has_codex:
    run_codex_review()

if has_gemini:
    run_gemini_review()

# 結果を集計
any_needs_revision = (
    review_results["codex"]["needs_revision"] or
    review_results["gemini"]["needs_revision"]
)
any_ready = (
    review_results["codex"]["ready"] or
    review_results["gemini"]["ready"]
)
any_success = (
    review_results["codex"]["success"] or
    review_results["gemini"]["success"]
)

# 結果の表示と判定
print_footer()

if any_needs_revision:
    print_status("❌ プランに修正が必要です。上記の指摘を確認してください。")
    print_footer()
    sys.exit(2)

if any_ready:
    print_status("✅ AIプランレビュー完了 - 問題なし")
elif any_success:
    print_status("⚠️  AIプランレビュー完了 - 明確な承認なし（続行を許可）")
else:
    print_status("⚠️  AIレビューが実行できませんでした（続行を許可）")

print_footer()
sys.exit(0)
