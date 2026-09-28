#!/bin/sh
set -eu

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"

exec "${data_home}/input-source/run-cached-swift" select-input-source "$@"
