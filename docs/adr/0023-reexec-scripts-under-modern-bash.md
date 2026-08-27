# ADR 0023: 古い bash で起動されたスクリプトを新しい bash で実行し直す

## Status

Accepted

## Context

`script/lib/` の共通ライブラリは `typeset -g` / `declare -A` / `local -n` といった
新しい bash の構文を使う。`declare -A` は 4.0、`typeset -g` は 4.2、`local -n` は 4.3 で
追加されたため、実際の下限は **4.3** である。一方 macOS に同梱される `/bin/bash` は 3.2.57 で止まっており、
スクリプトの `#!/usr/bin/env bash` が **PATH 上で最初に見つかった bash** に解決される。

実測した問題は PATH の順序である。この Mac の場合、Claude Code など GUI から起動された
プロセスが継承する PATH は `/bin`（4番目）が `/opt/homebrew/bin`（14番目）より前にあり、
`env bash` が 3.2 に解決される。対話 zsh では `/opt/homebrew/bin` が先頭なので、
手で叩けば通るが自動実行だけが落ちるという再現しづらい形になっていた。

結果として `npm test` が 58 件失敗した。CI（Ubuntu / bash 5）は緑のままなので、
ローカルでだけ壊れ、しかも「brew install bash して PATH に追加してください」という
既に満たしているはずの案内が出る。

同じ構図が Python にもあった。`script/codex-config-merge.py` は `tomllib` を使うため
3.11 以上が必要だが、テストが `python3` を直接呼んでおり macOS の 3.9 に解決されていた。

## Decision

**`script/lib/output.sh` が、古い bash で起動されたスクリプトを新しい bash で
実行し直す。** 判定と探索は 2 つの関数に分ける。

- `output::bash_is_supported <major> <minor>` — 下限 4.3 を満たすか判定する。
- `output::find_modern_bash` — PATH を先頭から走査し、条件を満たす最初の `bash` を返す。
- `output::should_reexec_bash <entry> <argv0> <major> <minor>` — 再実行の可否を判定する。

下限を「4 以上」にすると、PATH 上で 4.0〜4.2 が先に見つかった場合にそれを掴んでしまい、
再実行した先で別のエラーになったうえ「4 以上なので再実行しない」と判断されて詰む。

再実行時は **PATH の先頭に新しい bash のディレクトリを差し込んでから `exec` する**。
親だけ作り直しても、子スクリプトの `#!/usr/bin/env bash` が古い bash に解決される
ままでは同じ場所で落ちるため。

`output.sh` を source していない入口スクリプト（`script/update-agents-md.sh`）には
source を追加した。

テスト側では、`python3` を直接呼ぶ代わりに PATH 上から 3.11 以上を選ぶ。

## Consequences

### Positive

- 起動元の PATH の並びに関係なくスクリプトが動く。素の PATH で `npm test` が
  58 failed → 0 failed になった。
- 判定ロジックが純関数として切り出されているため、bash 3.2 が無い環境（CI の Ubuntu）
  でも回帰テストが動く。
- 既存の呼び出し側に変更は要らない。`output.sh` を source していれば自動で効く。

### Negative

- スクリプトが自分自身を `exec` し直すため、**source より前に副作用があると
  二重実行になる**。現在の入口スクリプトはいずれも `set -euo pipefail` と
  `SCRIPT_DIR` の算出しかしていないため問題はないが、暗黙の前提が増えた。
- 再実行時に PATH を書き換えるので、新しい bash と同じディレクトリにある他のコマンドも
  優先されるようになる。
- `bats` から source された場合は再実行しない（実行し直すべき本体が無いため）。
  BATS を古い bash で起動した場合は従来どおりエラーになる。

### Mitigation

- 再実行先は「4.3 以降であること」を実際に起動して確認済みなので、子では判定が必ず
  偽になりループしない。別途フラグを持たない。
- 新しい bash が見つからない場合は従来どおり明示的なエラーメッセージで落とす。
- 上記の制約は `test/integration/lib_functions.bats` に回帰テストとして固定した。
