#!/bin/bash

#
# sake_build:
# -----------
# Run sake build
#
# assumes SITE_ROOT, HTDOCS_DIR, VERBOSE & MODE are available
#
# @arg siteroot - base dir of installation
# @arg htdocsdir - public html directory
# @arg verbose - show/hide output
# @arg mode - whether we run in lite or full mode
#

function sake_build() {
    SAKE_SUCCESS=true

    cd "$SITE_ROOT"/"$HTDOCS_DIR" || exit
    log_message false "Synching the database..." "$MESSAGE_INFO";

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
        log_message true "Database sync successful" "$MESSAGE_SUCCESS";
    else
        log_message true "Database sync failed" "$MESSAGE_ERROR";
    fi
}
