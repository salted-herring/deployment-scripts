#!/bin/bash

#
# bower_update:
# -------------
# Bower update
#
# assumes MODE, VERBOSE, CHOSEN_THEME, THEME_DIR & SITE_ROOT are available
#
#
function bower_update() {
    BOWER_SUCCESS=true

    if [ $MODE == "full" ] && [ "$BOWER" = true ]
    then
        log_message false "Updating bower (please be patient - this may take some time)..." "$MESSAGE_INFO";

        cd $THEME_DIR/$CHOSEN_THEME;

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

        cd $SITE_ROOT;
    fi
}
