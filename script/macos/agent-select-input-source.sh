#!/bin/sh
set -eu

src="${HOME}/.config/karabiner/select-input-source.swift"

exec /usr/bin/xcrun swift "$src" "$@"
