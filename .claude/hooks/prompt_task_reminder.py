#!/usr/bin/env python3
"""UserPromptSubmit Hook: 作業着手前のタスク登録を促す

依頼を受けた直後に TaskCreate でタスクを作成させ、進行状況を TaskUpdate で
可視化させる。タスク登録はモデルの裁量に任せると抜けるため、プロンプト受信時に
毎回 additionalContext として指示を注入して既定動作にする。

ブロックはしない（UserPromptSubmit で exit 2 するとプロンプト自体が破棄され、
依頼が失われる）。純粋な質問への回答だけで完結する場合は不要である旨も
指示文に含め、過剰なタスク作成を防ぐ。
"""
import json
import sys

from common import load_hook_input

INSTRUCTION = (
    "【タスク管理】作業を伴う依頼の場合は、着手前に TaskCreate でタスクを作成してから実装を始めること。"
    "着手時に TaskUpdate で in_progress、完了時に completed へ更新する。"
    "質問への回答や確認だけで完結する依頼、および3ステップ未満の些末な作業では作成しなくてよい。"
)


def main() -> int:
    try:
        data = load_hook_input()
    except ValueError:
        # stdin が壊れていてもプロンプトの処理を止めない
        return 0

    if not (data.get("prompt") or "").strip():
        return 0

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": INSTRUCTION,
                }
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
