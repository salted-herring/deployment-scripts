#!/bin/bash

#
# maintenance_mode:
# -----------------
# If the SilverStripe module "maintenance-mode" exists in the htdocs folder,
# we will either put the site into maintenance mode or turn it off.
#
# assumes SITE_ROOT, HTDOCS_DIR, & VERBOSE are available
#
# @arg mode - "on" or "off"
#

function maintenance_mode() {
    local mode=$1

    MAINTENANCE_SUCCESS=true

    cd "$SITE_ROOT"/"$HTDOCS_DIR" || exit

    if [ ! -d "$SITE_ROOT"/"$HTDOCS_DIR"/maintenance-mode ]
    then
        log_message true "Maintenance module is not installed" "$MESSAGE_ERROR";
    else
        log_message false "Setting maintenance mode: "$MODE"..." "$MESSAGE_INFO";

        if [ "$VERBOSE" = true ]
        then
            if ! (php framework/cli-script.php dev/tasks/MaintenanceMode "$mode")
            then
                MAINTENANCE_SUCCESS=false
            fi
        else
            if ! (php framework/cli-script.php dev/tasks/MaintenanceMode "$mode" &>/dev/null)
            then
                MAINTENANCE_SUCCESS=false
            fi
        fi

        if [ "$MAINTENANCE_SUCCESS" = true ]
        then
            log_message true "Maintenance mode successfully changed" "$MESSAGE_SUCCESS";
        else
            log_message true "Maintenance mode change failed" "$MESSAGE_ERROR";
        fi
    fi
}
