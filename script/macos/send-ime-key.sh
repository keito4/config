#!/bin/sh
set -eu

# home-manager installs the source here regardless of XDG_DATA_HOME
src="${HOME}/.local/share/input-source/send-ime-key.swift"

# Interpret with Apple-signed swift-frontend. A prebuilt ad-hoc binary is not
# covered by skhd's Accessibility grant, so its key events are silently dropped.
if ! /usr/bin/xcrun swift "$src" "$@"; then
  msg="xcrun swift failed. If Xcode was updated, run: sudo xcodebuild -license accept"
  echo "send-ime-key: $msg" >&2
  # display notification は無人起動 (skhd 経由) だと出ないことがあるため alert を使う
  /usr/bin/osascript -e "display alert \"send-ime-key failed\" message \"$msg\"" >/dev/null 2>&1 &
  exit 1
fi
