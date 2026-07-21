#!/bin/sh
set -eu

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
src="${data_home}/input-source/send-ime-key.swift"

exec /usr/bin/xcrun swift "$src" "$@"
