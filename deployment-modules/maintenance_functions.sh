#!/bin/bash

MAINTENANCE_SUCCESS=true

#
# maintenance_mode:
# -----------------
# If the SilverStripe module "maintenance-mode" exists in the htdocs folder,
# we will either put the site into maintenance mode or turn it off.
#
# @arg siteroot - base dir of installation
# @arg htdocsdir - public html directory
# @arg verbose - show/hide output
# @arg mode - "on" or "off"
#

function maintenance_mode() {
    local SITE_ROOT=$1
    local HTDOCS_DIR=$2
    local VERBOSE=$3
    local MODE=$4

    cd "$SITE_ROOT"/"$HTDOCS_DIR" || exit

    if [ ! -d "$SITE_ROOT"/"$HTDOCS_DIR"/maintenance-mode ]
    then
        echo -e "\e[31mMaintenance module is not installed ✗\e[39m"
    else
        echo -e "\e[38;5;237mSetting maintenance mode: "$MODE"...\e[39m"

        if [ "$VERBOSE" = true ]
        then
            if ! (php framework/cli-script.php dev/tasks/MaintenanceMode "$MODE")
            then
                MAINTENANCE_SUCCESS=false
            fi
        else
            if ! (php framework/cli-script.php dev/tasks/MaintenanceMode "$MODE" &>/dev/null)
            then
                MAINTENANCE_SUCCESS=false
            fi
        fi

        if [ "$MAINTENANCE_SUCCESS" = true ]
        then
            echo -e "\e[32mMaintenance mode successfully changed ✓\e[39m"
        else
            echo -e "\e[31mMaintenance mode change failed ✗\e[39m"
        fi
    fi
}
