#!/usr/bin/env python3
"""
PR作成後にAIレビューを自動実行するPostToolUseフック

gh pr create 成功後に自動的にCodexとGeminiによるコードレビューを実行します。
インストールされているツールのみ実行されます。
レビュー結果はPRコメントとして投稿されます。
問題が検出された場合は修正を促します。
"""
import sys
import json
import subprocess
import shutil
import os
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

# モデル設定（空文字列の場合はCLIのデフォルトモデルを使用）
CODEX_MODEL = ""  # デフォルトモデルを使用（ChatGPTアカウント互換）
GEMINI_MODEL = ""  # デフォルトモデルを使用

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

# レビュープロンプト（日本語で出力）
review_prompt = """あなたは他のエンジニアが作成したコード変更のレビュアーとして行動してください。
正確性、パフォーマンス、セキュリティ、保守性、開発者体験に影響する問題に焦点を当ててください。
変更によって導入されたアクション可能な問題のみを指摘してください。
問題を指摘する際は、簡潔で直接的な説明と、影響を受けるファイルと行範囲を記載してください。
重大な問題を優先し、diffの理解を妨げない限りは細かい指摘は避けてください。
発見事項をリストした後、全体的な正確性の判定（'patch is correct' または 'patch is incorrect'）を簡潔な理由と0から1の信頼度スコアとともに出力してください。
現在のブランチをorigin/mainと比較してレビューしてください。
git merge-baseを使用してマージベースを見つけ、そのマージベースからHEADまでのdiffをレビューしてください。

**重要: 必ず日本語で回答してください。**"""

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

    codex_command = ["codex", "exec", "--sandbox", "read-only"]
    if CODEX_MODEL:
        codex_command.extend(["-m", CODEX_MODEL])
    codex_command.append(review_prompt)

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

        # Gemini用のプロンプト（diffを含める、日本語で出力）
        gemini_prompt = f"""あなたはコード変更のレビュアーとして行動してください。
正確性、パフォーマンス、セキュリティ、保守性、開発者体験に影響する問題に焦点を当ててください。
変更によって導入されたアクション可能な問題のみを指摘してください。
問題を指摘する際は、簡潔で直接的な説明と、影響を受けるファイルと行範囲を記載してください。
重大な問題を優先し、diffの理解を妨げない限りは細かい指摘は避けてください。
発見事項をリストした後、全体的な正確性の判定（'patch is correct' または 'patch is incorrect'）を簡潔な理由と0から1の信頼度スコアとともに出力してください。

**重要: 必ず日本語で回答してください。**

## レビュー対象のGit Diff:

{diff_content[:50000]}"""

        gemini_command = ["gemini", "-p", gemini_prompt]
        if GEMINI_MODEL:
            gemini_command.insert(1, GEMINI_MODEL)
            gemini_command.insert(1, "-m")

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

def check_for_issues(review_text: str) -> bool:
    """レビュー結果から問題が検出されたかをチェック"""
    if not review_text:
        return False
    lower_text = review_text.lower()
    # "patch is incorrect" または重大な問題の指摘を検出
    return "patch is incorrect" in lower_text or "high:" in lower_text or "critical:" in lower_text


# PRコメント用のマークダウンを生成
comment_parts = [f"## 🔍 AI Code Review (Local Hook)\n"]
codex_model_display = CODEX_MODEL or "default"
gemini_model_display = GEMINI_MODEL or "default"
comment_parts.append(f"**Models:** Codex ({codex_model_display}) / Gemini ({gemini_model_display})\n")

issues_found = False

if review_results["codex"]:
    comment_parts.append("### 🤖 Codex Review\n")
    comment_parts.append(review_results["codex"])
    comment_parts.append("\n")
    if check_for_issues(review_results["codex"]):
        issues_found = True

if review_results["gemini"]:
    comment_parts.append("### ✨ Gemini Review\n")
    comment_parts.append(review_results["gemini"])
    comment_parts.append("\n")
    if check_for_issues(review_results["gemini"]):
        issues_found = True

# 問題が検出された場合、修正を促すメッセージを追加
if issues_found:
    comment_parts.append("\n---\n")
    comment_parts.append("### ⚠️ 修正が必要です\n")
    comment_parts.append("上記のレビューで問題が指摘されています。修正してからマージしてください。\n")

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
if issues_found:
    print("⚠️  AIレビュー完了 - 問題が検出されました。修正を検討してください。", file=sys.stderr)
else:
    print("✅ AIレビュー完了", file=sys.stderr)
print("=" * 60, file=sys.stderr)

# PostToolUseフックは常に成功で終了（ブロックしない）
sys.exit(0)
