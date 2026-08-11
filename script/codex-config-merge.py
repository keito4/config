#!/usr/bin/env -S uv run --script --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomli-w>=1.0,<2"]
# ///
"""リポジトリの .codex/config.toml（共有ベース）を端末の config.toml へマージ配備する。

Codex / ChatGPT アプリは projects.*.trust_level・marketplaces.*・プラグイン有効化
状態・絶対パス入りの MCP サーバー定義などの端末固有状態を $CODEX_HOME/config.toml
自体に書き戻す。そのため実体を git 追跡ファイルへの symlink にはできない。

  - リポジトリ .codex/config.toml : 共有ベース（追跡・clean を維持）
  - ~/.codex/config.toml          : Codex が所有する実ファイル（端末状態はここに残る）

マージ規則: テーブルは再帰的にマージし、ベースが定義するキーはベースが勝つ。
ローカルにしか無いキー（端末状態）はそのまま保持する。
配備先が symlink の場合はリンク先の内容をローカル状態として取り込んだうえで
実ファイルに置き換える（symlink 環境からの自動移行）。

注意: 書き込みは TOML を再シリアライズするため、配備先ファイル内のコメントは
残らない（ベースのコメントはリポジトリ側に正本がある）。

Usage: codex-config-merge.py <base_toml> <target_toml>
"""

import os
import sys
import tomllib
from pathlib import Path
from typing import Any

import tomli_w


def deep_merge(local: Any, base: Any) -> Any:
    """base を local に重ねる。dict は再帰マージ、それ以外は base 優先。"""
    if isinstance(local, dict) and isinstance(base, dict):
        merged = dict(local)
        for key, value in base.items():
            merged[key] = deep_merge(local[key], value) if key in local else value
        return merged
    return base


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {Path(sys.argv[0]).name} <base_toml> <target_toml>", file=sys.stderr)
        return 2

    base_path = Path(sys.argv[1])
    target_path = Path(sys.argv[2])

    try:
        base = tomllib.loads(base_path.read_text())
    except (OSError, tomllib.TOMLDecodeError) as err:
        print(f"⚠️  ベースを読めません: {base_path}: {err}", file=sys.stderr)
        return 1

    local = {}
    if target_path.exists():
        try:
            local = tomllib.loads(target_path.read_text())
        except tomllib.TOMLDecodeError as err:
            # 壊れたローカルを黙って捨てると端末状態が消えるため、手当てを促して止める
            print(f"⚠️  配備先の TOML が不正です（修正するまでマージ中断）: {target_path}: {err}", file=sys.stderr)
            return 1

    output = tomli_w.dumps(deep_merge(local, base))

    was_symlink = target_path.is_symlink()
    if not was_symlink and target_path.exists() and target_path.read_text() == output:
        return 0

    if was_symlink:
        target_path.unlink()

    tmp_path = target_path.with_suffix(".toml.tmp")
    tmp_path.write_text(output)
    os.replace(tmp_path, target_path)

    if was_symlink:
        print(f"🔀 symlink を実ファイルへ移行してマージ配備しました: {target_path}")
    else:
        print(f"🔀 ベースをマージ配備しました: {target_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
