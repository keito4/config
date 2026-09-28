#!/bin/sh
# Run an input-source Swift helper from a cached, prebuilt binary.
#
# Usage: run-cached-swift <name> [args...]
#        run-cached-swift --build <name>   (build only; used by activation)
#
# Interpreting the helper with `xcrun swift` at hotkey time breaks whenever the
# Xcode license agreement is reset by an Xcode update (xcrun exits 69 and the
# shortcut silently does nothing). Instead, compile once per source hash into
# $XDG_CACHE_HOME/input-source and exec the binary. Activation prebuilds it, so
# hotkeys only need xcrun again after the Swift source itself changes.
set -eu

build_only=0
if [ "${1:-}" = "--build" ]; then
  build_only=1
  shift
fi

name="${1:?usage: run-cached-swift [--build] <name> [args...]}"
shift

# home-manager installs the sources here regardless of XDG_DATA_HOME
src="${HOME}/.local/share/input-source/${name}.swift"
bin_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/input-source"

hash="$(/usr/bin/shasum -a 256 "$src" | cut -c1-16)"
bin="${bin_dir}/${name}-${hash}"

if [ ! -x "$bin" ]; then
  mkdir -p "$bin_dir"
  tmp="${bin_dir}/.${name}.tmp.$$"
  log="${bin_dir}/${name}.build.log"
  if ! /usr/bin/xcrun swiftc -O -o "$tmp" "$src" >"$log" 2>&1; then
    rm -f "$tmp"
    msg="swiftc build failed (see ${log}). If Xcode was updated, run: sudo xcodebuild -license accept"
    echo "run-cached-swift: $msg" >&2
    # display notification は無人起動 (skhd 経由) だと出ないことがあるため alert を使う
    /usr/bin/osascript -e "display alert \"IME helper (${name}) failed\" message \"$msg\"" >/dev/null 2>&1 &
    exit 1
  fi
  mv -f "$tmp" "$bin"
fi

if [ "$build_only" -eq 1 ]; then
  # 古いハッシュのビルドは activation のときだけ掃除する（ホットキー実行と競合させない）
  for old in "${bin_dir}/${name}"-*; do
    [ "$old" = "$bin" ] || rm -f "$old"
  done
  exit 0
fi

exec "$bin" "$@"
