#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo 'usage: send-ime-key <kana|eisuu>' >&2
  exit 64
fi

case "$1" in
  kana) key=0x68 ;;
  eisuu) key=0x66 ;;
  *)
    echo 'usage: send-ime-key <kana|eisuu>' >&2
    exit 64
    ;;
esac

# Reuse the signed, Accessibility-approved daemon binary instead of starting
# Swift for every keypress. Physical IME keys also update Google's active mode.
exec /usr/local/bin/skhd -k "$key"
