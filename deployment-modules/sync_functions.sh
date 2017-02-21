#!/bin/bash



#
# sync_files:
# -------------
# Syncs all files from the repository to the live site
#
# assumes SITE_ROOT, HTDOCS_DIR, VERBOSE, REPO_DIR & are available
#
# @arg siteroot - base dir of installation
# @arg verbose - show/hide output
# @arg htdocsdir - public html directory
# @arg repodir -location of the repo directory
#

function sync_files() {

    SYNC_SUCCESS=true

    cd "$SITE_ROOT" || exit
    log_message false "Synching the repo & $HTDOCS_DIR..." "$MESSAGE_INFO";

    if [ "$VERBOSE" = true ]
    then
        if ! (rsync -av --delete "$REPO_DIR"/ "$HTDOCS_DIR" --exclude .git* --exclude .gitignore --exclude .gitmodules --exclude readme.txt --exclude .htaccess --exclude robots.txt --exclude assets)
        then
            log_message true "Synchronisation failed" "$MESSAGE_ERROR";
            SYNC_SUCCESS=false
        fi
    else
        if ! (rsync -a --delete "$REPO_DIR"/ "$HTDOCS_DIR" --exclude .git* --exclude .gitignore --exclude .gitmodules --exclude readme.txt --exclude .htaccess --exclude robots.txt --exclude assets)
        then
            log_message true "Synchronisation failed" "$MESSAGE_ERROR";
            SYNC_SUCCESS=false
        fi
    fi

    if [ "$SYNC_SUCCESS" = true ]
    then
        log_message true "Synchronisation successfully completed" "$MESSAGE_SUCCESS";
    fi
}
