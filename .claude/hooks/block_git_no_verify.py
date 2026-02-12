#!/usr/bin/env python3
import sys
import json
import shlex

# Read input from Claude
data = json.load(sys.stdin)
cmd = (data.get("tool_input", {}) or {}).get("command") or ""
tokens = shlex.split(cmd) if cmd else []

if not tokens:
    sys.exit(0)

block = False
sanitized = []
seen_git = False
seen_commit = False

for t in tokens:
    # Block HUSKY=0 environment variable
    if t == "HUSKY=0":
        block = True
        continue

    if t == "git":
        seen_git = True
        sanitized.append(t)
        continue

    if seen_git and t == "commit":
        seen_commit = True
        sanitized.append(t)
        continue

    # Block --no-verify flag
    if t == "--no-verify":
        block = True
        continue

    # Block -n shorthand for --no-verify after commit
    if seen_commit and t == "-n":
        block = True
        continue

    sanitized.append(t)

# Create sanitized command
sanitized_cmd = shlex.join(sanitized) if sanitized else ""

if block:
    sys.stderr.write(
        "❌ `--no-verify`や`HUSKY=0`は使用禁止です。\n"
        "✅ 代わりに次のコマンドを実行してください:\n"
        f"{sanitized_cmd}\n"
    )
    sys.stderr.flush()
    sys.exit(2)

sys.exit(0)
