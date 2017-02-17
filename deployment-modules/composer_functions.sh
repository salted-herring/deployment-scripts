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
    mode=$1
    verbose=$2

    if [ "$mode" == "full" ]; then
        echo -e "\e[38;5;237mUpdating composer (please be patient - this may take some time)... ";
        if [ "$verbose" = true ]
        then
            if ! (composer update)
            then
                COMPOSER_SUCCESS=false
                echo -e "\e[31mComposer update failed ✗\e[39m";
            fi
        else
            if ! (composer --quiet update)
            then
                COMPOSER_SUCCESS=false
                echo -e "\e[31mComposer update failed ✗\e[39m";
            fi
        fi

        if [ "$COMPOSER_SUCCESS" = true ]
        then
            echo -e "\e[32mComposer successfully updated ✓\e[39m";
        fi
    fi
}
