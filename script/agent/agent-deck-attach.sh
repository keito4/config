#!/usr/bin/env bash
# agent-deck のセッションを peco で選んでアタッチする
# agent-deck 独自の attach は使わず、素の tmux attach でアタッチする
set -euo pipefail

# cmux.app は自前の terminfo だけを収めたディレクトリを TERMINFO に設定するが、
# tmux 内 (TERM=tmux-256color) では該当エントリが無い。peco が使う termbox-go は
# ncurses と違い TERMINFO_DIRS へフォールバックしないため Init() が失敗し、空の
# funcs を参照して panic する。zsh 側 (.zshenv) にも同じガードがあるが、修正前から
# 起動している古いシェルから呼ばれても落ちないよう、ここでも同じ判定を行う。
if [ -n "${TERMINFO:-}" ] && [ -n "${TERM:-}" ]; then
  if ! compgen -G "$TERMINFO/*/$TERM" >/dev/null 2>&1; then
    unset TERMINFO
  fi
fi

die() {
  echo "ada: $1" >&2
  exit 1
}

# 以前は agent-deck の stderr を捨てたうえで set -e に任せていたため、どの段階で
# 失敗しても何も表示されずに終了していた。失敗は必ず理由を出す。
if ! rows=$(agent-deck list --json); then
  die "agent-deck list --json に失敗しました"
fi

list=$(printf '%s\n' "$rows" \
  | jq -r '.[] | select(.archived | not) | [.id, .group, .title, .status, .path] | @tsv' \
  | column -t -s $'\t')

if [ -z "$list" ]; then
  die "アタッチできるセッションがありません（archived 済みのみ）"
fi

# peco の終了コードは「キャンセル」と「異常終了」を区別する必要があるため、
# set -e に処理させず自前で見る。
peco_rc=0
sel=$(printf '%s\n' "$list" | peco --prompt 'agent-deck>' --query "${1:-}") || peco_rc=$?

if [ "$peco_rc" -ne 0 ]; then
  # peco はキャンセル時に 1、SIGINT で 130 を返す。それ以外は異常終了。
  case "$peco_rc" in
    1 | 130) exit 0 ;;
    *) die "peco が異常終了しました (exit $peco_rc)" ;;
  esac
fi

[ -z "$sel" ] && exit 0
id="${sel%% *}"

tmux_session=$(printf '%s\n' "$rows" \
  | jq -r --arg id "$id" '.[] | select(.id == $id) | .tmux_session')

if [ -z "$tmux_session" ] || [ "$tmux_session" = "null" ]; then
  die "セッション情報が取得できませんでした: $id"
fi

# tmux プロセスが死んでいたら起動を待ってからアタッチ
if ! tmux has-session -t "=$tmux_session" 2>/dev/null; then
  agent-deck session start "$id"
  for _ in $(seq 1 20); do
    tmux has-session -t "=$tmux_session" 2>/dev/null && break
    sleep 0.25
  done
  if ! tmux has-session -t "=$tmux_session" 2>/dev/null; then
    die "tmux セッションが起動しませんでした: $tmux_session"
  fi
fi

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$tmux_session" || die "switch-client に失敗しました: $tmux_session"
else
  tmux attach -t "=$tmux_session" || die "attach に失敗しました: $tmux_session"
fi
