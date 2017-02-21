#!/bin/bash

# ###########################################
# utilities.sh
# ----------------
# Provides general/utility functions
# ###########################################

#
# interactive:
# -------------
# Prevents continued execution until user has interacted with the system.
#
# assumes INTERACTIVE is available.
#
function interactive() {
    if [ "$INTERACTIVE" = true ]
    then
        read -rsp $'Press any key to continue...\n' -n1 key
    fi
}
