#!/usr/bin/env python3
"""Git の検証フック（Quality Gates）を無効化する操作をブロックする。

--no-verify だけを見ていると素通りする抜け道が複数ある。2026-07-15 に
`git -c core.hooksPath=/dev/null commit` がこのフックをすり抜けた（止めたのは
Claude Code 側の分類器で、このフックではなかった）ため、以下を検知対象にする:

  - HUSKY=0                              husky の無効化
  - --no-verify / -n / -nm 等             commit の検証スキップ（結合フラグ含む）
  - git -c core.hooksPath=...            その場でフックパスを差し替え
  - git config core.hooksPath ...        永続的に無効化（以降の全コミットが素通し）
  - git --config-env=core.hooksPath=...  環境変数経由の差し替え
  - GIT_CONFIG_KEY_n=core.hooksPath      環境変数経由の差し替え
  - GIT_CONFIG_GLOBAL=/dev/null 等       設定ファイルごと無効化
"""
import re
import shlex
import sys

from common import get_command, load_hook_input

HOOKS_PATH_KEY = "core.hookspath"

# GIT_CONFIG_KEY_0=core.hooksPath のような環境変数経由の指定
GIT_CONFIG_KEY_RE = re.compile(r"^GIT_CONFIG_KEY_\d+=(.+)$", re.IGNORECASE)
# 対になる GIT_CONFIG_VALUE_n / GIT_CONFIG_COUNT
GIT_CONFIG_PAIR_RE = re.compile(r"^GIT_CONFIG_(VALUE_\d+|COUNT)=", re.IGNORECASE)
# GIT_CONFIG_GLOBAL=/dev/null / GIT_CONFIG_SYSTEM=/dev/null（設定ごと無効化）
GIT_CONFIG_FILE_RE = re.compile(r"^GIT_CONFIG(_GLOBAL|_SYSTEM)?=", re.IGNORECASE)
# -n を含む結合ショートフラグ（-nm, -vn など）。--long は対象外。
COMBINED_SHORT_FLAG_RE = re.compile(r"^-([a-zA-Z]+)$")

CONFIG_ENV_PREFIX = "--config-env="


def _is_hooks_path(value: str) -> bool:
    """core.hooksPath への言及か（git の設定キーは大文字小文字を区別しない）"""
    return value.strip().lower().startswith(HOOKS_PATH_KEY)


def evaluate(cmd: str):
    """コマンド文字列を評価し (ブロックすべきか, 無害化したコマンド) を返す。"""
    tokens = shlex.split(cmd) if cmd else []
    if not tokens:
        return False, ""

    block = False
    sanitized = []
    seen_git = False
    seen_commit = False
    seen_config = False

    i = 0
    while i < len(tokens):
        t = tokens[i]

        # --- 環境変数による無効化 -------------------------------------------
        if t == "HUSKY=0":
            block = True
            i += 1
            continue

        key_match = GIT_CONFIG_KEY_RE.match(t)
        if key_match:
            if _is_hooks_path(key_match.group(1)):
                block = True
                # 既に積んだ対の変数（COUNT/VALUE）も落とす
                sanitized = [s for s in sanitized if not GIT_CONFIG_PAIR_RE.match(s)]
                i += 1
                while i < len(tokens) and GIT_CONFIG_PAIR_RE.match(tokens[i]):
                    i += 1
                continue
            sanitized.append(t)
            i += 1
            continue

        if GIT_CONFIG_FILE_RE.match(t):
            block = True
            i += 1
            continue

        # --- git 本体 -------------------------------------------------------
        if t == "git":
            seen_git = True
            sanitized.append(t)
            i += 1
            continue

        if seen_git and t == "commit":
            seen_commit = True
            sanitized.append(t)
            i += 1
            continue

        if seen_git and t == "config":
            seen_config = True
            sanitized.append(t)
            i += 1
            continue

        # git config [--global] core.hooksPath <path> — 永続的な無効化
        if seen_config and _is_hooks_path(t):
            block = True
            i += 1
            if i < len(tokens) and not tokens[i].startswith("-"):
                i += 1  # 続く値も落とす
            continue

        # git -c core.hooksPath=... / git -ccore.hooksPath=...
        if t == "-c" and i + 1 < len(tokens) and _is_hooks_path(tokens[i + 1]):
            block = True
            i += 2
            continue

        if t.startswith("-c") and len(t) > 2 and _is_hooks_path(t[2:]):
            block = True
            i += 1
            continue

        # git --config-env=core.hooksPath=ENVVAR
        if t.startswith(CONFIG_ENV_PREFIX) and _is_hooks_path(t[len(CONFIG_ENV_PREFIX) :]):
            block = True
            i += 1
            continue

        # --- 検証スキップフラグ ---------------------------------------------
        if t == "--no-verify":
            block = True
            i += 1
            continue

        # commit の -n / -nm のような結合ショートフラグ
        # （push の -n は --dry-run で無害なため commit のみ対象）
        if seen_commit:
            combined = COMBINED_SHORT_FLAG_RE.match(t)
            if combined and "n" in combined.group(1):
                block = True
                remaining = combined.group(1).replace("n", "")
                if remaining:
                    sanitized.append(f"-{remaining}")
                i += 1
                continue

        sanitized.append(t)
        i += 1

    return block, (shlex.join(sanitized) if sanitized else "")


def main() -> int:
    data = load_hook_input()
    block, sanitized_cmd = evaluate(get_command(data))

    if not block:
        return 0

    sys.stderr.write(
        "❌ Quality Gates を無効化する操作は禁止です。\n"
        "   （--no-verify / -n / HUSKY=0 / core.hooksPath の差し替え）\n"
        "✅ 代わりに次のコマンドを実行してください:\n"
        f"{sanitized_cmd}\n"
    )
    sys.stderr.flush()
    return 2


if __name__ == "__main__":
    sys.exit(main())
