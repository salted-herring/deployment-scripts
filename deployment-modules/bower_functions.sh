#!/bin/bash

BOWER_SUCCESS=true

#
# bower_update:
# -------------
# Bower update
#
# @arg mode - whether we run in lite or full mode
# @arg verbose - show/hide output
# @arg theme - theme to run bower inside
# @arg themedir - base theme directory
# @arg siteroot - base dir of installation
#
function bower_update() {
    local MODE=$1
    local VERBOSE=$2
    local THEME=$3
    local THEMEDIR=$4
    local SITEROOT=$5

    if [ $MODE == "full" ]; then
        log_message false "Updating bower (please be patient - this may take some time)..." "$MESSAGE_INFO";

        cd $THEMEDIR/$THEME;

        if [ "$VERBOSE" = true ]
        then
            if ! (bower update)
            then
                BOWER_SUCCESS=false
                log_message true "Bower update failed" "$MESSAGE_ERROR";
            fi
        else
            if ! (bower --quiet update &>/dev/null)
            then
                BOWER_SUCCESS=false
                log_message true "Bower update failed" "$MESSAGE_ERROR";
            fi
        fi

        if [ "$BOWER_SUCCESS" = true ]
        then
            log_message true "Bower successfully updated" "$MESSAGE_SUCCESS";
        fi

        cd $SITEROOT;
    fi
}
