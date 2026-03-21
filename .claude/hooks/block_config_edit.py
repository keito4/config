#!/usr/bin/env python3
"""PreToolUse Hook: リンター・フォーマッター設定ファイルの編集をブロック

エージェントがリンターエラーに直面した場合、コードを修正する代わりに
リンター設定を緩和してテストをパスさせようとすることがある。
このフックはそれを防止する。

参考: Harness Engineering ベストプラクティス
  - 「コードを修正せよ、リンター設定を変更するな」
"""
import sys
import json

data = json.load(sys.stdin)
tool_input = data.get("tool_input", {}) or {}
file_path = tool_input.get("file_path") or tool_input.get("path") or ""

if not file_path:
    sys.exit(0)

# ── 保護対象のファイルパターン ──────────────────────────────
PROTECTED_BASENAMES = {
    # ESLint
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    ".eslintrc.yml",
    ".eslintrc.yaml",
    "eslint.config.js",
    "eslint.config.mjs",
    "eslint.config.cjs",
    "eslint.config.ts",
    # Biome
    "biome.json",
    "biome.jsonc",
    # Prettier
    ".prettierrc",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.json",
    ".prettierrc.yml",
    ".prettierrc.yaml",
    ".prettierrc.toml",
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
    # TypeScript
    "tsconfig.json",
    # Ruff (Python)
    "ruff.toml",
    # Lefthook / Husky
    "lefthook.yml",
    "lefthook-local.yml",
    # golangci-lint
    ".golangci.yml",
    ".golangci.yaml",
    # Clippy (Rust) - Cargo.toml の [lints] セクション
    # Cargo.toml は汎用すぎるためここでは除外
    # SwiftLint
    ".swiftlint.yml",
    # ShellCheck
    ".shellcheckrc",
    # Pre-commit
    ".pre-commit-config.yaml",
    # Oxlint
    ".oxlintrc.json",
}

# pyproject.toml は [tool.ruff] 等のリンター設定を含むが
# 汎用的すぎるためデフォルトでは保護しない

# ── パス判定 ───────────────────────────────────────────────
from pathlib import PurePosixPath

basename = PurePosixPath(file_path).name

if basename in PROTECTED_BASENAMES:
    msg = (
        f"BLOCKED: {basename} はリンター/フォーマッター設定ファイルです。\n"
        f"コードを修正してください。設定を緩和してはいけません。\n"
        f"FIX: リンターエラーの指示に従い、該当するソースコードを修正してください。"
    )
    print(msg, file=sys.stderr)
    sys.exit(2)

sys.exit(0)
