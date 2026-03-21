#!/usr/bin/env python3
"""
git commit後にアーキテクチャ関連の変更を検出し、ADR作成をリマインドするPostToolUseフック

アーキテクチャに影響する変更（依存関係、設定、エントリポイント等）を検知し、
docs/adr/ にADRが含まれていない場合にリマインドを表示します。
"""
import sys
import json
import subprocess
import re

data = json.load(sys.stdin)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
tool_response = data.get("tool_response", {}) or {}

if tool_name != "Bash":
    sys.exit(0)

command = tool_input.get("command", "").strip()

if not re.search(r"git\s+commit", command):
    sys.exit(0)

# --help, --dry-run は除外
if any(flag in command for flag in ["--help", "-h", "--dry-run", "-n"]):
    sys.exit(0)

# コミットが実際に成功したか確認（tool_responseのstdoutをチェック）
stdout = tool_response.get("stdout", "")
stderr = tool_response.get("stderr", "")
combined = stdout + stderr
# 成功パターン: "[branch hash] message" 形式
if not re.search(r"\[[^\]]+\s+[0-9a-f]{5,}\]", combined):
    sys.exit(0)

# HEADの変更ファイルを取得
try:
    result = subprocess.run(
        ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"],
        capture_output=True,
        text=True,
        timeout=5,
    )
    changed = result.stdout.strip()
except Exception:
    sys.exit(0)

if not changed:
    sys.exit(0)

files = changed.split("\n")

# ADRが含まれていればリマインド不要
if any(f.startswith("docs/adr/") for f in files):
    sys.exit(0)

# アーキテクチャシグナルの検出
signals = []
patterns = [
    (r"(^|/)package\.json$", "package.json (dependency changes)"),
    (r"(^|/)(biome\.json|\.eslintrc|oxlint|eslint\.config)", "Linter/Formatter config"),
    (r"(^|/)tsconfig.*\.json$", "TypeScript config"),
    (r"(^|/)(lefthook\.yml|\.claude/settings\.json)", "Harness/Hook config"),
    (r"^src/.*/index\.|^src/.*/main\.", "Module entry point"),
    (r"(^|/)Dockerfile", "Container config"),
    (r"(^|/)docker-compose", "Container orchestration"),
    (r"(^|/)terraform/", "Infrastructure as Code"),
    (r"(^|/)\.github/workflows/", "CI/CD workflows"),
    (r"(^|/)supabase/migrations/", "Database migrations"),
]

for f in files:
    for pattern, label in patterns:
        if re.search(pattern, f):
            if label not in signals:
                signals.append(label)

if not signals:
    sys.exit(0)

signal_list = "\n".join(f"- {s}" for s in signals)
msg = (
    f"This commit contains architectural changes:\n{signal_list}\n"
    f"Consider creating an ADR in docs/adr/ if this is a significant decision. "
    f"Skip if the change is routine."
)

output = {
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": msg,
    }
}
json.dump(output, sys.stdout)
sys.exit(0)
