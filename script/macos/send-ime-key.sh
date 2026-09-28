#!/bin/sh
set -eu

# home-manager installs the runner here regardless of XDG_DATA_HOME
exec "${HOME}/.local/share/input-source/run-cached-swift" send-ime-key "$@"
