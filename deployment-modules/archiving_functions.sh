#!/bin/bash

#
# archive_site:
# -------------
# Archives htdocs & latest sql dump into one tar zip.
#
# assumes SITE_ROOT, HTDOCS_DIR, VERBOSE, VERSION_NAME,
# SQL_DUMPS_DIR, MYSQL_DATABASE & VERSIONS_DIR are available.
#
# @arg backup_version - version name of the database dump (likely a date/timestamp)
#

function archive_site() {
    local backup_version=$1

    HTDOCS_SUCCESS=true

    cd "$SITE_ROOT" || exit
    echo -e "\e[38;5;237mArchiving the current $HTDOCS_DIR...";

    if [ "$VERBOSE" = true ]
    then
        if ! (tar -czvf "$VERSION_NAME".tgz --exclude=assets "$HTDOCS_DIR" "$SQL_DUMPS_DIR"/"$MYSQL_DATABASE"-"$backup_version".sql)
        then
            HTDOCS_SUCCESS=false
        fi
    else
        if ! (tar -czf "$VERSION_NAME".tgz --exclude=assets "$HTDOCS_DIR" "$SQL_DUMPS_DIR"/"$MYSQL_DATABASE"-"$backup_version".sql)
        then
            HTDOCS_SUCCESS=false
        fi
    fi

    if [ "$HTDOCS_SUCCESS" = true ]
    then
        cd "$VERSIONS_DIR" || exit
        ln -sf "$(basename "$VERSION_NAME".tgz)" latest

        log_message true "$HTDOCS_DIR successfully archived" "$MESSAGE_SUCCESS";
    else
        log_message true "$HTDOCS_DIR archiving failed" "$MESSAGE_ERROR";
    fi

    # clean up sql
    rm -rf "${SITE_ROOT:?}"/"$SQL_DUMPS_DIR"
}
