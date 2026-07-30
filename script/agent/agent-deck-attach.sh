#!/usr/bin/env bash
# agent-deck のセッションを peco で選んでアタッチする
# agent-deck 独自の attach は使わず、素の tmux attach でアタッチする
set -euo pipefail

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
