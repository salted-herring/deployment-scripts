#!/bin/bash

HTDOCS_SUCCESS=true

#
# archive_site:
# -------------
# Archives htdocs & latest sql dump into one tar zip.
#
# @arg siteroot - base dir of installation
# @arg htdocsdir - public html directory
# @arg verbose - show/hide output
# @arg versionname - the version name for this archive (likely a date/timestamp)
# @arg sqldumpdir - the directory where sqldumps live
# @arg mysqldatabase - the name of the database to archive
# @arg databaseversion - version name of the database dump (likely a date/timestamp)
# @arg versionsdir - directory where versions are archived to
#

function archive_site() {
    local SITE_ROOT=$1
    local HTDOCS_DIR=$2
    local VERBOSE=$3
    local VERSION_NAME=$4
    local SQL_DUMPS_DIR=$5
    local MYSQL_DATABASE=$6
    local DATABASE_VERSION=$7
    local VERSIONS_DIR=$8

    cd "$SITE_ROOT" || exit
    echo -e "\e[38;5;237mArchiving the current $HTDOCS_DIR...";

    if [ "$VERBOSE" = true ]
    then
        if ! (tar -czvf "$VERSION_NAME".tgz --exclude=assets "$HTDOCS_DIR" "$SQL_DUMPS_DIR"/"$MYSQL_DATABASE"-"$DATABASE_VERSION".sql)
        then
            HTDOCS_SUCCESS=false
        fi
    else
        if ! (tar -czf "$VERSION_NAME".tgz --exclude=assets "$HTDOCS_DIR" "$SQL_DUMPS_DIR"/"$MYSQL_DATABASE"-"$DATABASE_VERSION".sql)
        then
            HTDOCS_SUCCESS=false
        fi
    fi

    if [ "$HTDOCS_SUCCESS" = true ]
    then
        cd "$VERSIONS_DIR" || exit
        ln -sf "$(basename "$VERSION_NAME".tgz)" latest
        echo -e "\e[32m$HTDOCS_DIR successfully archived ✓\e[39m";
    else
        echo -e "\e[31m$HTDOCS_DIR archiving failed ✗\e[39m";
    fi

    # clean up sql
    rm -rf "${SITE_ROOT:?}"/"$SQL_DUMPS_DIR"
}
