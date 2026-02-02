#!/usr/bin/env python3
"""
PR作成後にAIレビューを自動実行するPostToolUseフック

gh pr create 成功後に自動的にCodexとGeminiによるコードレビューを実行します。
インストールされているツールのみ実行されます。
クリティカルな問題（patch is incorrect）が検出された場合は警告を表示します。
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

# レビュー結果を格納
review_results = []


def parse_verdict(output: str) -> dict:
    """レビュー結果から verdict と confidence を抽出"""
    result = {
        "verdict": None,
        "confidence": None,
        "is_incorrect": False,
        "issues": []
    }

    if not output:
        return result

    output_lower = output.lower()

    # verdict を検出（より正確なパターンマッチング）
    # 引用符で囲まれた文字列（例: "patch is incorrect" という説明文）を除外
    # verdict/判定/結論の直後に出現するパターンを優先

    # verdict 行を探す（"verdict:" や "**verdict**" の後）
    verdict_patterns = [
        r"verdict[:\s*]+\*{0,2}patch is (incorrect|correct)\*{0,2}",
        r"overall[^:]*verdict[:\s*]+\*{0,2}patch is (incorrect|correct)\*{0,2}",
        r"判定[:\s*]+patch is (incorrect|correct)",
    ]

    for pattern in verdict_patterns:
        match = re.search(pattern, output_lower)
        if match:
            if match.group(1) == "incorrect":
                result["verdict"] = "incorrect"
                result["is_incorrect"] = True
            else:
                result["verdict"] = "correct"
            break

    # 上記で見つからない場合、文脈を考慮して検出
    if result["verdict"] is None:
        # 引用符で囲まれていない "patch is incorrect/correct" を検出
        # 引用符内を除外するために、行単位で判定
        for line in output.split('\n'):
            line_lower = line.lower()
            # 引用符内のテキストを除外
            if '"patch is incorrect"' in line_lower or "'patch is incorrect'" in line_lower:
                continue
            if '("patch is incorrect")' in line_lower:
                continue

            if "patch is incorrect" in line_lower:
                result["verdict"] = "incorrect"
                result["is_incorrect"] = True
                break
            elif "patch is correct" in line_lower:
                result["verdict"] = "correct"
                break

    # confidence を抽出（様々なフォーマットに対応）
    confidence_patterns = [
        r"confidence[:\s]+([0-9]+(?:\.[0-9]+)?)",
        r"confidence[:\s]+([0-9]+(?:\.[0-9]+)?)\s*/\s*1",
        r"([0-9]+(?:\.[0-9]+)?)\s*/\s*1",
    ]
    for pattern in confidence_patterns:
        match = re.search(pattern, output_lower)
        if match:
            try:
                result["confidence"] = float(match.group(1))
                break
            except ValueError:
                pass

    # 問題点を抽出（行番号を含む行を検出）
    issue_pattern = r"[-•]\s*(.+?(?:line|\.(?:py|js|ts|tsx|md|json|yml|yaml))[^\n]*)"
    issues = re.findall(issue_pattern, output, re.IGNORECASE)
    result["issues"] = issues[:5]  # 最大5件

    return result


def run_codex_review() -> str:
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

        output = result.stdout or ""
        if output:
            print(output, file=sys.stderr)

        if result.returncode != 0 and result.stderr:
            print(f"⚠️  Codexエラー: {result.stderr[:300]}", file=sys.stderr)

        return output

    except subprocess.TimeoutExpired:
        print("⚠️  Codexレビューがタイムアウトしました（10分）", file=sys.stderr)
        return ""
    except Exception as e:
        print(f"⚠️  Codexレビュー実行エラー: {e}", file=sys.stderr)
        return ""


def run_gemini_review() -> str:
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
            return ""

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
            return ""

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

        output = result.stdout or ""
        if output:
            print(output, file=sys.stderr)

        # returncode が 0 でない場合はエラーとして扱う
        # ただし、stdout に有効な出力がある場合は警告のみ
        if result.returncode != 0:
            stderr_content = result.stderr.strip() if result.stderr else ""

            # 既知の警告パターン（致命的でないもの）
            warning_patterns = [
                "hook registry initialized",
                "failed to connect to ide",
                "extension is running"
            ]
            is_only_warning = stderr_content and all(
                any(pattern in line.lower() for pattern in warning_patterns)
                for line in stderr_content.split('\n') if line.strip()
            )

            if is_only_warning and output:
                # 既知の警告のみで、かつ有効な出力がある場合はスキップ
                pass
            elif stderr_content:
                # stderr に内容がある場合は最初の意味のある行を表示
                first_line = next(
                    (line.strip() for line in stderr_content.split('\n') if line.strip()),
                    stderr_content[:100]
                )
                print(f"⚠️  Geminiエラー (exit {result.returncode}): {first_line[:300]}", file=sys.stderr)
            else:
                # stderr が空の場合
                print(f"⚠️  Geminiエラー: 終了コード {result.returncode}", file=sys.stderr)

        return output

    except subprocess.TimeoutExpired:
        print("⚠️  Geminiレビューがタイムアウトしました（10分）", file=sys.stderr)
        return ""
    except Exception as e:
        print(f"⚠️  Geminiレビュー実行エラー: {e}", file=sys.stderr)
        return ""


print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print("🔍 PR作成完了。AIレビューを実行中...", file=sys.stderr)
print("=" * 60, file=sys.stderr)

# 利用可能なツールでレビューを実行し、結果を収集
if has_codex:
    codex_output = run_codex_review()
    codex_result = parse_verdict(codex_output)
    codex_result["reviewer"] = "Codex"
    review_results.append(codex_result)

if has_gemini:
    gemini_output = run_gemini_review()
    gemini_result = parse_verdict(gemini_output)
    gemini_result["reviewer"] = "Gemini"
    review_results.append(gemini_result)

# レビュー結果の解析
incorrect_reviews = [r for r in review_results if r["is_incorrect"]]
has_critical_issues = len(incorrect_reviews) > 0

print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)

if has_critical_issues:
    print("🚨 クリティカルな問題が検出されました！", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    print("", file=sys.stderr)

    for review in incorrect_reviews:
        reviewer = review.get("reviewer", "Unknown")
        confidence = review.get("confidence")
        confidence_str = f" (confidence: {confidence})" if confidence else ""
        print(f"❌ {reviewer}: patch is incorrect{confidence_str}", file=sys.stderr)

        if review.get("issues"):
            print("   主な指摘事項:", file=sys.stderr)
            for issue in review["issues"][:3]:
                print(f"   • {issue[:100]}", file=sys.stderr)

    print("", file=sys.stderr)
    print("─" * 60, file=sys.stderr)
    print("⚠️  対応が必要です:", file=sys.stderr)
    print("   1. 上記の指摘事項を確認してください", file=sys.stderr)
    print("   2. 必要に応じてコードを修正してください", file=sys.stderr)
    print("   3. 修正後、PRを更新してください", file=sys.stderr)
    print("─" * 60, file=sys.stderr)
else:
    print("✅ AIレビュー完了", file=sys.stderr)

    # 成功した場合も verdict サマリーを表示
    for review in review_results:
        reviewer = review.get("reviewer", "Unknown")
        verdict = review.get("verdict", "unknown")
        confidence = review.get("confidence")
        confidence_str = f" (confidence: {confidence})" if confidence else ""

        if verdict == "correct":
            print(f"   ✓ {reviewer}: patch is correct{confidence_str}", file=sys.stderr)
        elif verdict:
            print(f"   ? {reviewer}: {verdict}{confidence_str}", file=sys.stderr)

print("=" * 60, file=sys.stderr)

# PostToolUseフックは常に成功で終了（ブロックしない）
# ※ PR は既に作成されているため、ブロックしても意味がない
#   代わりに警告メッセージで対応を促す
sys.exit(0)
