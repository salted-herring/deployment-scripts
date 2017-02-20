#!/bin/bash

COMPOSER_SUCCESS=true

#
# composer_update:
# ----------------
# Update composer
#
# @arg mode - whether we run in lite or full mode
# @arg verbose - show/hide output
#
function composer_update() {
    local mode=$1
    local verbose=$2

    if [ "$mode" == "full" ]; then
        log_message false "Updating Composer (please be patient - this may take some time)..." "$MESSAGE_INFO";
        if [ "$verbose" = true ]
        then
            if ! (composer update)
            then
                COMPOSER_SUCCESS=false
                log_message true "Composer update failed" "$MESSAGE_ERROR";
            fi
        else
            if ! (composer --quiet update)
            then
                COMPOSER_SUCCESS=false
                log_message true "Composer update failed" "$MESSAGE_ERROR";
            fi
        fi

        if [ "$COMPOSER_SUCCESS" = true ]
        then
            log_message true "Composer successfully update" "$MESSAGE_SUCCESS";
        fi
    fi
}
