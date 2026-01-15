#!/usr/bin/env python3
"""
PR作成後にCodexレビューを自動実行するPostToolUseフック

gh pr create 成功後に自動的にCodexによるコードレビューを実行します。
"""
import sys
import json
import subprocess
import shutil
import os

# Read input from Claude
data = json.load(sys.stdin)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
tool_response = data.get("tool_response", {}) or {}

# Bashツールでない場合はスキップ
if tool_name != "Bash":
    sys.exit(0)

# コマンドを取得
command = tool_input.get("command", "")

# gh pr create コマンドかどうかを判定
if "gh pr create" not in command:
    sys.exit(0)

# ツール実行が成功したかチェック
stdout = tool_response.get("stdout", "")
stderr = tool_response.get("stderr", "")

# PR URLが出力に含まれていれば成功と判断
if "github.com" not in stdout and "github.com" not in stderr:
    # PR作成が失敗した可能性
    sys.exit(0)

# Codex CLIがインストールされているか確認
if not shutil.which("codex"):
    print("⚠️  Codex CLIがインストールされていません。スキップします。", file=sys.stderr)
    sys.exit(0)

# Codexレビューを実行
print("", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print("🔍 PR作成完了。Codexレビューを実行中...", file=sys.stderr)
print("=" * 60, file=sys.stderr)
print("", file=sys.stderr)

codex_prompt = """You are acting as a reviewer for a proposed code change made by another engineer.
Focus on issues that impact correctness, performance, security, maintainability, or developer experience.
Flag only actionable issues introduced by the change.
When you flag an issue, provide a short, direct explanation and cite the affected file and line range.
Prioritize severe issues and avoid nit-level comments unless they block understanding of the diff.
After listing findings, produce an overall correctness verdict ('patch is correct' or 'patch is incorrect') with a concise justification and a confidence score between 0 and 1.
Review the current branch against origin/main.
Use git merge-base to find the merge base, then review the diff from that merge base to HEAD."""

codex_command = [
    "codex", "exec",
    "--sandbox", "read-only",
    codex_prompt
]

try:
    result = subprocess.run(
        codex_command,
        cwd=os.getcwd(),
        capture_output=True,
        text=True,
        timeout=600  # 10分タイムアウト
    )

    print("## Codex Review Results", file=sys.stderr)
    print("", file=sys.stderr)

    if result.stdout:
        print(result.stdout, file=sys.stderr)

    if result.returncode != 0 and result.stderr:
        print(f"⚠️  Codexエラー: {result.stderr}", file=sys.stderr)

    print("", file=sys.stderr)
    print("=" * 60, file=sys.stderr)
    print("✅ Codexレビュー完了", file=sys.stderr)
    print("=" * 60, file=sys.stderr)

except subprocess.TimeoutExpired:
    print("⚠️  Codexレビューがタイムアウトしました（10分）", file=sys.stderr)

except Exception as e:
    print(f"⚠️  Codexレビュー実行エラー: {e}", file=sys.stderr)

# PostToolUseフックは常に成功で終了（ブロックしない）
sys.exit(0)
