#!/bin/bash

function check_and_commit() {
    cd $REPO_PATH

    bash ./script/export.sh

    if [[ `git status --porcelain` ]]; then
        git add .
        aicommits --all
    fi
}

check_and_commit
