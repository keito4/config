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

sel=$(agent-deck list --json 2>/dev/null \
  | jq -r '.[] | select(.archived | not) | [.id, .group, .title, .status, .path] | @tsv' \
  | column -t -s $'\t' \
  | peco --prompt 'agent-deck>' --query "${1:-}")

[ -z "$sel" ] && exit 0
id="${sel%% *}"

tmux_session=$(agent-deck list --json 2>/dev/null \
  | jq -r --arg id "$id" '.[] | select(.id == $id) | .tmux_session')

if [ -z "$tmux_session" ] || [ "$tmux_session" = "null" ]; then
  echo "セッション情報が取得できませんでした: $id" >&2
  exit 1
fi

# tmux プロセスが死んでいたら起動を待ってからアタッチ
if ! tmux has-session -t "=$tmux_session" 2>/dev/null; then
  agent-deck session start "$id"
  for _ in $(seq 1 20); do
    tmux has-session -t "=$tmux_session" 2>/dev/null && break
    sleep 0.25
  done
  if ! tmux has-session -t "=$tmux_session" 2>/dev/null; then
    echo "tmux セッションが起動しませんでした: $tmux_session" >&2
    exit 1
  fi
fi

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$tmux_session"
else
  tmux attach -t "=$tmux_session"
fi
