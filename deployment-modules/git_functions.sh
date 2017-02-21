#!/bin/bash

#
# git_fail:
# ---------
# If git fails, print appropriate error message & exit.
#
# @arg - action: name of the action that failed - e.g. "pull branchname"
#
function git_fail() {
    log_message true "Repository retrieval failed" "$MESSAGE_ERROR";

    if ! [ -z "$1" ]
    then
        log_message true "$1 failed" "$MESSAGE_ERROR";
    fi

    log_message true "$1 Deployment failed" "$MESSAGE_ERROR";
    exit 1
}

#
# git_fetch:
# ---------
# Fetch & Pull the git repo
#
# assumes SITE_ROOT, REPO_DIR & VERBOSE are available
#
# @arg branch - branch to pull
# @arg repo path - local path where the repo exists
# @arg verbose - turn on/off output
function git_fetch() {
    local branch=$1

    GIT_SUCCESS=true

    log_message false "Git attempting to pull from \e[1m$branch\e[22m..." "$MESSAGE_INFO";
    cd "$SITE_ROOT"/"$REPO_DIR"

    if [ "$VERBOSE" = true ]
    then
        if ! (git fetch --all)
        then
            GIT_SUCCESS=false;
            git_fail "fetch";
        fi
        if ! (git checkout $branch) then
            GIT_SUCCESS=false
            git_fail "checkout $branch";
        fi
        if ! (git pull origin $branch) then
            GIT_SUCCESS=false
            git_fail "pull $branch";
        fi
    else
        if ! (git fetch --all &> /dev/null) then
            GIT_SUCCESS=false;
            git_fail "fetch";
        fi
        if ! (git checkout --quiet $branch) then
            GIT_SUCCESS=false
            git_fail "checkout $branch";
        fi
        if ! (git pull --quiet origin $branch) then
            GIT_SUCCESS=false
            git_fail "pull $branch";
        fi
    fi

    if [ "$GIT_SUCCESS" = true ]
    then
        log_message true "Git successfully pulled from $branch branch" "$MESSAGE_SUCCESS";
    else
        git_fail
    fi
}
