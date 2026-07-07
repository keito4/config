#!/bin/sh
set -eu

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
src="${data_home}/input-source/select-input-source.swift"

exec /usr/bin/xcrun swift "$src" "$@"
