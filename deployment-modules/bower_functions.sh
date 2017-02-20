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
        echo -e "\e[38;5;237mUpdating bower (please be patient - this may take some time)... ";

        cd $THEMEDIR/$THEME;

        if [ "$VERBOSE" = true ]
        then
            echo 1
            exit
            if ! (bower update)
            then
                BOWER_SUCCESS=false
                echo -e "\e[31mBower update failed ✗\e[39m";
            fi
        else
            if ! (bower --quiet update &>/dev/null)
            then
                BOWER_SUCCESS=false
                echo -e "\e[31mBower update failed ✗\e[39m";
            fi
        fi

        if [ "$BOWER_SUCCESS" = true ]
        then
            echo -e "\e[32mBower successfully updated ✓\e[39m";
        fi

        cd $SITEROOT;
    fi
}
