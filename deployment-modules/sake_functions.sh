#!/bin/bash

SAKE_SUCCESS=true

#
# sake_build:
# -----------
# Run sake build
#
# @arg siteroot - base dir of installation
# @arg htdocsdir - public html directory
# @arg verbose - show/hide output
# @arg mode - whether we run in lite or full mode
#

function sake_build() {
    local SITE_ROOT=$1
    local HTDOCS_DIR=$2
    local VERBOSE=$3
    local MODE=$4

    cd "$SITE_ROOT"/"$HTDOCS_DIR" || exit
    echo -e "\e[38;5;237mSynching the database...\e[39m"

    if [ "$VERBOSE" = true ]
    then
        if [ "$MODE" == "full" ]
        then
            if ! (php framework/cli-script.php dev/build flush=all)
            then
                SAKE_SUCCESS=false
            fi
        else
            if ! (php framework/cli-script.php dev/build)
            then
                SAKE_SUCCESS=false
            fi
        fi
    else
        if [ "$MODE" == "full" ]
        then
            if ! (php framework/cli-script.php dev/build flush=all &>/dev/null)
            then
                SAKE_SUCCESS=false
            fi
        else
            if ! (php framework/cli-script.php dev/build &>/dev/null)
            then
                SAKE_SUCCESS=false
            fi
        fi
    fi

    if [ "$SAKE_SUCCESS" = true ]
    then
        echo -e "\e[32mdatabase sync successful ✓\e[39m"
    else
        echo -e "\e[31mdatabase sync failed ✗\e[39m"
    fi
}
