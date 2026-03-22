#!/usr/bin/env python3
"""
git commit後にアーキテクチャ関連の変更を検出し、ADR作成をリマインドするPostToolUseフック

アーキテクチャに影響する変更（依存関係、設定、エントリポイント等）を検知し、
docs/adr/ にADRが含まれていない場合にリマインドを表示します。
"""
import sys
import json
import shutil
import subprocess
import re
import shlex

data = json.load(sys.stdin)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
tool_response = data.get("tool_response", {}) or {}

if tool_name != "Bash":
    sys.exit(0)

command = tool_input.get("command", "").strip()

if not re.search(r"git\s+commit", command):
    sys.exit(0)

# --help, --dry-run は除外（-n は git commit -n = --no-verify のため除外しない）
try:
    tokens = shlex.split(command)
except ValueError:
    tokens = command.split()
if any(flag in tokens for flag in ["--help", "-h", "--dry-run"]):
    sys.exit(0)

# コミットが実際に成功したか確認
# tool_response の exit code を優先、フォールバックとして stdout パターンを検査
exit_code = tool_response.get("exit_code")
if exit_code is not None:
    if exit_code != 0:
        sys.exit(0)
else:
    # exit_code が取得できない場合は stdout の "[branch hash] message" パターンで判定
    stdout = tool_response.get("stdout", "")
    stderr = tool_response.get("stderr", "")
    combined = stdout + stderr
    if not re.search(r"\[[^\]]+\s+[0-9a-f]{4,}\]", combined):
        sys.exit(0)

# HEADの変更ファイルを取得
git_bin = shutil.which("git")
if not git_bin:
    sys.exit(0)

try:
    result = subprocess.run(
        [git_bin, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"],
        capture_output=True,
        text=True,
        timeout=5,
    )
    if result.returncode != 0:
        sys.exit(0)
    changed = result.stdout.strip()
except (subprocess.TimeoutExpired, OSError):
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
