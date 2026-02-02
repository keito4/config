#!/usr/bin/env python3
"""
PR作成後にAIレビューを自動実行するPostToolUseフック

gh pr create 成功後に自動的にCodexとGeminiによるコードレビューを実行します。
インストールされているツールのみ実行されます。
レビュー結果はPRコメントとして投稿されます。
"""
import sys
import json
import subprocess
import shutil
import os
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

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

# PR URLを抽出
pr_url_match = re.search(pr_url_pattern, combined_output)
if not pr_url_match:
    sys.exit(0)

pr_url = pr_url_match.group(0)

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
print(f"📎 PR: {pr_url}", file=sys.stderr)
print("=" * 60, file=sys.stderr)


def run_codex_review():
    """Codexによるレビューを実行し、結果を返す"""
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

        # returncode == 0 の場合のみ結果を返す
        if result.returncode == 0 and result.stdout:
            print(result.stdout, file=sys.stderr)
            return result.stdout.strip()

        if result.returncode != 0:
            error_msg = result.stderr[:300] if result.stderr else "不明なエラー"
            print(f"⚠️  Codexエラー: {error_msg}", file=sys.stderr)
            return None

    except subprocess.TimeoutExpired:
        print("⚠️  Codexレビューがタイムアウトしました（10分）", file=sys.stderr)
        return None
    except Exception as e:
        print(f"⚠️  Codexレビュー実行エラー: {e}", file=sys.stderr)
        return None

    return None


def run_gemini_review():
    """Geminiによるレビューを実行し、結果を返す"""
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
            return None

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
            return None

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

        # returncode == 0 の場合のみ結果を返す
        if result.returncode == 0 and result.stdout:
            print(result.stdout, file=sys.stderr)
            return result.stdout.strip()

        if result.returncode != 0:
            error_msg = result.stderr[:300] if result.stderr else "不明なエラー"
            print(f"⚠️  Geminiエラー: {error_msg}", file=sys.stderr)
            return None

    except subprocess.TimeoutExpired:
        print("⚠️  Geminiレビューがタイムアウトしました（10分）", file=sys.stderr)
        return None
    except Exception as e:
        print(f"⚠️  Geminiレビュー実行エラー: {e}", file=sys.stderr)
        return None

    return None


def post_pr_comment(pr_url: str, comment_body: str):
    """PRにコメントを投稿"""
    try:
        result = subprocess.run(
            ["gh", "pr", "comment", pr_url, "--body", comment_body],
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode == 0:
            print("✅ PRコメント投稿成功", file=sys.stderr)
            return True
        else:
            print(f"⚠️  PRコメント投稿失敗: {result.stderr[:200]}", file=sys.stderr)
            return False
    except Exception as e:
        print(f"⚠️  PRコメント投稿エラー: {e}", file=sys.stderr)
        return False


# レビュー結果を格納
review_results = {"codex": None, "gemini": None}

# 利用可能なツールでレビューを並列実行
with ThreadPoolExecutor(max_workers=2) as executor:
    futures = {}
    if has_codex:
        futures[executor.submit(run_codex_review)] = "codex"
    if has_gemini:
        futures[executor.submit(run_gemini_review)] = "gemini"

    for future in as_completed(futures):
        reviewer = futures[future]
        try:
            review_results[reviewer] = future.result()
        except Exception as e:
            print(f"⚠️  {reviewer}レビュー実行エラー: {e}", file=sys.stderr)

# PRコメント用のマークダウンを生成
comment_parts = ["## 🔍 AI Code Review (Local Hook)\n"]

if review_results["codex"]:
    comment_parts.append("### 🤖 Codex Review\n")
    comment_parts.append(review_results["codex"])
    comment_parts.append("\n")

if review_results["gemini"]:
    comment_parts.append("### ✨ Gemini Review\n")
    comment_parts.append(review_results["gemini"])
    comment_parts.append("\n")

# レビュー結果がある場合のみPRにコメント投稿
if review_results["codex"] or review_results["gemini"]:
    comment_parts.append("\n---\n")
    comment_parts.append("*🤖 Generated by post_pr_ai_review.py hook*")
    comment_body = "\n".join(comment_parts)

    print("", file=sys.stderr)
    print("📝 PRにレビューコメントを投稿中...", file=sys.stderr)
    post_pr_comment(pr_url, comment_body)
else:
    print("", file=sys.stderr)
    print("⚠️  レビュー結果がないため、PRコメントはスキップします", file=sys.stderr)

print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print("✅ AIレビュー完了", file=sys.stderr)
print("=" * 60, file=sys.stderr)

# PostToolUseフックは常に成功で終了（ブロックしない）
sys.exit(0)
