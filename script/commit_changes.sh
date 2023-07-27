#!/bin/bash

repo_path="~/develop/github.com/keito4/config"

function check_and_commit() {
    cd $repo_path

    bash ./script/export.sh

    if [[ `git status --porcelain` ]]; then
        git add .
        git-aicommit
    fi
}

check_and_commit
