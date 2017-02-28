#!/bin/bash

GIT_SUCCESS=true

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
# assumes SITE_ROOT, REPO_DIR, CHOSEN_REPO_TARGET, CHOSEN_REPO_MODE & VERBOSE are available
#
# @arg branch - branch to pull
# @arg repo path - local path where the repo exists
# @arg verbose - turn on/off output
#
function git_fetch() {
    GIT_SUCCESS=true

    log_message false "Git attempting to pull from \e[1m$CHOSEN_REPO_TARGET\e[22m..." "$MESSAGE_INFO";

    cd "$SITE_ROOT"/"$REPO_DIR"

    if [ "$CHOSEN_REPO_MODE" = "branch" ]
    then
        git_checkout_branch
    elif [ "$CHOSEN_REPO_MODE" = "tag" ]
    then
        git_checkout_tag
    else
        log_message true "Incorrect repo mode supplied. Valid options are: branch, tag" "$MESSAGE_ERROR";
    fi
}


#
# git_checkout_branch:
# --------------------
# Checkout the specified branch
#
# assumes CHOSEN_REPO_TARGET & VERBOSE are available
#
function git_checkout_branch() {
    if [ "$VERBOSE" = true ]
    then
        if ! (git fetch --all)
        then
            GIT_SUCCESS=false;
            git_fail "fetch";
        fi
        if ! (git stash) then
            GIT_SUCCESS=false
            git_fail "stash";
        fi
        if ! (git checkout $CHOSEN_REPO_TARGET) then
            GIT_SUCCESS=false
            git_fail "checkout $CHOSEN_REPO_TARGET";
        fi
        if ! (git pull origin $CHOSEN_REPO_TARGET) then
            GIT_SUCCESS=false
            git_fail "pull $CHOSEN_REPO_TARGET";
        fi
    else
        if ! (git fetch --all &> /dev/null) then
            GIT_SUCCESS=false;
            git_fail "fetch";
        fi
        if ! (git stash --quiet &> /dev/null) then
            GIT_SUCCESS=false
            git_fail "stash";
        fi
        if ! (git checkout --quiet $CHOSEN_REPO_TARGET) then
            GIT_SUCCESS=false
            git_fail "checkout $CHOSEN_REPO_TARGET";
        fi
        if ! (git pull --quiet origin $CHOSEN_REPO_TARGET) then
            GIT_SUCCESS=false
            git_fail "pull $CHOSEN_REPO_TARGET";
        fi
    fi

    if [ "$GIT_SUCCESS" = true ]
    then
        log_message true "Git successfully checked out $CHOSEN_REPO_TARGET branch" "$MESSAGE_SUCCESS";
    else
        git_fail
    fi
}


#
# git_checkout_tag:
# -----------------
# Checkout the specified tag
#
# assumes CHOSEN_REPO_TARGET & VERBOSE are available
#
function git_checkout_tag() {
    if [ "$VERBOSE" = true ]
    then
        if ! (git fetch --tags)
        then
            GIT_SUCCESS=false;
            git_fail "fetch";
        fi
        if ! (git checkout $CHOSEN_REPO_TARGET) then
            GIT_SUCCESS=false
            git_fail "checkout $CHOSEN_REPO_TARGET";
        fi
    else
        if ! (git fetch --tags &> /dev/null) then
            GIT_SUCCESS=false;
            git_fail "fetch";
        fi
        if ! (git checkout --quiet $CHOSEN_REPO_TARGET) then
            GIT_SUCCESS=false
            git_fail "checkout $CHOSEN_REPO_TARGET";
        fi
    fi

    if [ "$GIT_SUCCESS" = true ]
    then
        log_message true "Git successfully checked out $CHOSEN_REPO_TARGET tag" "$MESSAGE_SUCCESS";
    else
        git_fail
    fi
}


#
# get_git_target:
# ---------------
# Find the target mode required of the deployment (i.e. from tag or branch)
# then save this & it's target.
#
# assumes SITE_ROOT, REPO_DIR, CHOSEN_REPO_MODE, CHOSEN_REPO_TARGET, MESSAGE_ERROR & VERBOSE are available
#
function get_git_target() {
    if [ "$CHOSEN_REPO_MODE" = "branch" ]
    then
        git_verify_branch
    elif [ "$CHOSEN_REPO_MODE" = "tag" ]
    then
        git_verify_tag
    else
        log_message true "Incorrect repo mode supplied. Valid options are: branch, tag" "$MESSAGE_ERROR";
    fi
}


#
# git_verify_tag:
# ---------------
# Verify the tag & if verfied set the chosen target to the supplied tag
#
# assumes SITE_ROOT, REPO_DIR, CHOSEN_REPO_MODE, CHOSEN_REPO_TARGET, MESSAGE_ERROR & VERBOSE are available
#
function git_verify_tag() {
    if [ "$CHOSEN_REPO_TARGET" = 0 ]
    then
        echo -e "\n"
        echo -e "Which tag should we deploy from?: \e[1m[$DEFAULT_TAG]\e[22m "
        read branch
        CHOSEN_REPO_TARGET="$tag"
    fi

    cd "$SITE_ROOT/$REPO_DIR" || exit

    if ! (git fetch --tags)
    then
        log_message true "Can't fetch tags for this repo. You may want to perform a mainual git fetch before running this again." "$MESSAGE_ERROR";
        exit
    fi

    if ! (git rev-parse --verify "$CHOSEN_REPO_TARGET" &>/dev/null)
    then
        log_message true "Can't find the $CHOSEN_REPO_TARGET tag in the current repository. You may want to perform a mainual git fetch before running this again." "$MESSAGE_ERROR";
        exit
    fi

    echo -e "   • Deployment tag: \e[1m$CHOSEN_REPO_TARGET\e[22m"
}


#
# git_verify_branch:
# ------------------
# Verify the branch & if verfied set the chosen target to the supplied branch
#
# assumes SITE_ROOT, REPO_DIR, CHOSEN_REPO_MODE, CHOSEN_REPO_TARGET, DEFAULT_BRANCH,
# MESSAGE_ERROR & VERBOSE are available
#
function git_verify_branch() {
    if [ "$CHOSEN_REPO_TARGET" = 0 ]
    then
        echo -e "\n"
        echo -e "Which branch should we deploy from?: \e[1m[$DEFAULT_BRANCH]\e[22m "
        read branch
        CHOSEN_REPO_TARGET="$CHOSEN_REPO_TARGET"
    fi

    cd "$SITE_ROOT/$REPO_DIR" || exit

    if ! (git rev-parse --verify "$CHOSEN_REPO_TARGET" &>/dev/null)
    then
        log_message true "Can't find the $CHOSEN_REPO_TARGET branch in the current repository. You may want to perform a git fetch before running this again." "$MESSAGE_ERROR";
        exit
    fi

    echo -e "   • Deployment branch: \e[1m$CHOSEN_REPO_TARGET\e[22m"
}
