#!/bin/sh
# Run an input-source Swift helper from a cached, prebuilt binary.
#
# Usage: run-cached-swift <name> [args...]
#        run-cached-swift --build <name>   (build only; used by activation)
#
# Interpreting the helper with `xcrun swift` at hotkey time breaks whenever the
# Xcode license agreement is reset by an Xcode update (xcrun exits 69 and the
# shortcut silently does nothing). Instead, compile once per source hash into
# $XDG_CACHE_HOME/input-source and exec the binary. If a rebuild fails, fall
# back to the most recent previous build so the shortcut keeps working.
set -eu

build_only=0
if [ "${1:-}" = "--build" ]; then
  build_only=1
  shift
fi

name="${1:?usage: run-cached-swift [--build] <name> [args...]}"
shift

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
cache_home="${XDG_CACHE_HOME:-${HOME}/.cache}"
src="${data_home}/input-source/${name}.swift"
bin_dir="${cache_home}/input-source"

notify_failure() {
  echo "run-cached-swift: $1" >&2
  # display notification は無人起動 (skhd 経由) だと出ないことがあるため alert を使う
  /usr/bin/osascript -e "display alert \"IME helper (${name}) failed\" message \"$1\"" >/dev/null 2>&1 &
}

hash="$(/usr/bin/shasum -a 256 "$src" | cut -c1-16)"
bin="${bin_dir}/${name}-${hash}"

if [ ! -x "$bin" ]; then
  mkdir -p "$bin_dir"
  tmp="${bin_dir}/.${name}.tmp.$$"
  log="${bin_dir}/${name}.build.log"
  if /usr/bin/xcrun swiftc -O -o "$tmp" "$src" >"$log" 2>&1; then
    mv -f "$tmp" "$bin"
    # 古いハッシュのビルドを掃除する
    for old in "${bin_dir}/${name}"-*; do
      [ "$old" = "$bin" ] || rm -f "$old"
    done
  else
    rm -f "$tmp"
    # fallback: 直前のビルド済みバイナリを使う
    fallback=""
    for old in "${bin_dir}/${name}"-*; do
      [ -x "$old" ] && fallback="$old"
    done
    if [ -z "$fallback" ]; then
      notify_failure "swiftc build failed (see ${log}). If Xcode was updated, run: sudo xcodebuild -license accept"
      exit 1
    fi
    echo "run-cached-swift: build failed, using previous build ${fallback} (see ${log})" >&2
    bin="$fallback"
  fi
fi

if [ "$build_only" -eq 1 ]; then
  exit 0
fi

exec "$bin" "$@"
