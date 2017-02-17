#!/bin/bash

GIT_SUCCESS=true

#
# git_fail:
# ---------
# If git fails, print appropriate error message & exit.
#
# @arg - branch name: name of the branch that failed
#
function git_fail() {
    echo -e "\e[31mRepository retrieval failed ✗\e[39m";

    if ! [ -z "$1" ]
    then
        echo -e "\e[31m$1 failed ✗\e[39m";
    fi

    echo -e "\e[31mDeployment failed ✗\e[39m";
    exit 1
}

#
# git_fetch:
# ---------
# Fetch & Pull the git repo
#
# @arg branch - branch to pull
# @arg repo path - local path where the repo exists
# @arg verbose - turn on/off output
function git_fetch() {
    branch=$1
    path=$2
    verbose=$3

    echo -e "\e[38;5;237mGit attempting to pull from \e[1m$branch\e[22m..."
    cd $path

    if [ "$verbose" = true ]
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
        echo -e "\e[32mGit successfully pulled from $branch branch ✓\e[39m";
    else
        git_fail
    fi
}
