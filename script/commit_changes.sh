#!/bin/bash

set -euo pipefail

function check_and_commit() {
    if [[ -z "${REPO_PATH:-}" ]]; then
        echo "REPO_PATH is not set" >&2
        return 1
    fi
    if [[ ! -d "$REPO_PATH" ]]; then
        echo "Directory $REPO_PATH does not exist" >&2
        return 1
    fi
    cd "$REPO_PATH" || return 1

    bash ./script/export.sh

    if [[ $(git status --porcelain) ]]; then
        git add .
        aicommits --all
    fi
}

check_and_commit
