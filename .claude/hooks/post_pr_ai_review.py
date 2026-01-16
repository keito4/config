#!/usr/bin/env python3
"""
PR作成後にAIレビューを自動実行するPostToolUseフック

gh pr create 成功後に自動的にCodexとGeminiによるコードレビューを実行します。
インストールされているツールのみ実行されます。
"""
import sys
import json
import subprocess
import shutil
import os
import re

# Read input from Claude
data = json.load(sys.stdin)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
tool_response = data.get("tool_response", {}) or {}

# Bashツールでない場合はスキップ
if tool_name != "Bash":
    sys.exit(0)

# コマンドを取得
command = tool_input.get("command", "").strip()

# gh pr create コマンドかどうかを厳密に判定（プレフィックス判定）
if not command.startswith("gh pr create"):
    sys.exit(0)

# ヘルプコマンドは除外
if "--help" in command or "-h" in command:
    sys.exit(0)

# ツール実行が成功したかチェック
stdout = tool_response.get("stdout", "")
stderr = tool_response.get("stderr", "")

# PR URLパターン（https://github.com/owner/repo/pull/123 形式）
pr_url_pattern = r"https://github\.com/[^/]+/[^/]+/pull/\d+"
combined_output = stdout + stderr

# PR URLが出力に含まれていれば成功と判断
if not re.search(pr_url_pattern, combined_output):
    sys.exit(0)

# 利用可能なAIツールを確認
has_codex = shutil.which("codex") is not None
has_gemini = shutil.which("gemini") is not None

if not has_codex and not has_gemini:
    print("⚠️  AIレビューツール（Codex/Gemini）がインストールされていません。スキップします。", file=sys.stderr)
    sys.exit(0)

# レビュープロンプト
review_prompt = """You are acting as a reviewer for a proposed code change made by another engineer.
Focus on issues that impact correctness, performance, security, maintainability, or developer experience.
Flag only actionable issues introduced by the change.
When you flag an issue, provide a short, direct explanation and cite the affected file and line range.
Prioritize severe issues and avoid nit-level comments unless they block understanding of the diff.
After listing findings, produce an overall correctness verdict ('patch is correct' or 'patch is incorrect') with a concise justification and a confidence score between 0 and 1.
Review the current branch against origin/main.
Use git merge-base to find the merge base, then review the diff from that merge base to HEAD."""

print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print("🔍 PR作成完了。AIレビューを実行中...", file=sys.stderr)
print("=" * 60, file=sys.stderr)


def run_codex_review():
    """Codexによるレビューを実行"""
    print("", file=sys.stderr)
    print("## 🤖 Codex Review", file=sys.stderr)
    print("-" * 40, file=sys.stderr)

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
            print(result.stdout, file=sys.stderr)

        if result.returncode != 0 and result.stderr:
            # エラー出力の先頭部分のみ表示
            print(f"⚠️  Codexエラー: {result.stderr[:300]}", file=sys.stderr)

    except subprocess.TimeoutExpired:
        print("⚠️  Codexレビューがタイムアウトしました（10分）", file=sys.stderr)
    except Exception as e:
        print(f"⚠️  Codexレビュー実行エラー: {e}", file=sys.stderr)


def run_gemini_review():
    """Geminiによるレビューを実行（diffをstdinで渡す）"""
    print("", file=sys.stderr)
    print("## ✨ Gemini Review", file=sys.stderr)
    print("-" * 40, file=sys.stderr)

    try:
        # マージベースを取得
        merge_base_result = subprocess.run(
            ["git", "merge-base", "origin/main", "HEAD"],
            capture_output=True,
            text=True,
            timeout=30
        )
        merge_base = merge_base_result.stdout.strip()

        if not merge_base:
            print("⚠️  マージベースの取得に失敗しました", file=sys.stderr)
            return

        # diffを取得
        diff_result = subprocess.run(
            ["git", "diff", merge_base, "HEAD"],
            capture_output=True,
            text=True,
            timeout=60
        )
        diff_content = diff_result.stdout

        if not diff_content:
            print("⚠️  diffが空です", file=sys.stderr)
            return

        # Gemini用のプロンプト（diffを含める）
        gemini_prompt = f"""You are acting as a reviewer for a proposed code change.
Focus on issues that impact correctness, performance, security, maintainability, or developer experience.
Flag only actionable issues introduced by the change.
When you flag an issue, provide a short, direct explanation and cite the affected file and line range.
Prioritize severe issues and avoid nit-level comments unless they block understanding of the diff.
After listing findings, produce an overall correctness verdict ('patch is correct' or 'patch is incorrect') with a concise justification and a confidence score between 0 and 1.

## Git Diff to Review:

{diff_content[:50000]}"""

        gemini_command = ["gemini", "-p", gemini_prompt]

        result = subprocess.run(
            gemini_command,
            cwd=os.getcwd(),
            capture_output=True,
            text=True,
            timeout=600
        )

        if result.stdout:
            print(result.stdout, file=sys.stderr)

        if result.returncode != 0 and result.stderr:
            print(f"⚠️  Geminiエラー: {result.stderr[:300]}", file=sys.stderr)

    except subprocess.TimeoutExpired:
        print("⚠️  Geminiレビューがタイムアウトしました（10分）", file=sys.stderr)
    except Exception as e:
        print(f"⚠️  Geminiレビュー実行エラー: {e}", file=sys.stderr)


# 利用可能なツールでレビューを実行
if has_codex:
    run_codex_review()

if has_gemini:
    run_gemini_review()

print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print("✅ AIレビュー完了", file=sys.stderr)
print("=" * 60, file=sys.stderr)

# PostToolUseフックは常に成功で終了（ブロックしない）
sys.exit(0)
