#!/bin/bash

#
# mysql_dump:
# -------------
# MySQL dump
#
# assumes SITE_ROOT, SQL_DUMPS_DIR, VERBOSE, MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD & MYSQL_DATABASE are available
#
# @arg backup_path - where the sql dump is stored (temporarily)
# @arg backup_version - a unique string to identify the dump (likely a timestamp)
#



function mysql_dump_fn() {
    local backup_version=$1

    MYSQL_SUCCESS=true

    log_message false "Starting MySQL dump..." "$MESSAGE_INFO";
    /bin/mkdir -p "$SITE_ROOT"/"$SQL_DUMPS_DIR"
    cd "$SITE_ROOT"/"$SQL_DUMPS_DIR" || exit

    if [ "$VERBOSE" = true ]
    then
        if ! (mysqldump -v -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "$MYSQL_DATABASE"-"$backup_version".sql)
        then
            MYSQL_SUCCESS=false
        fi
    else
        if ! (mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "$MYSQL_DATABASE"-"$backup_version".sql)
        then
            MYSQL_SUCCESS=false
        fi
    fi

    if [ "$MYSQL_SUCCESS" = true ]
    then
        log_message true "MySQL dump successful" "$MESSAGE_SUCCESS";
    else
        log_message true "MySQL dump failed" "$MESSAGE_ERROR";
    fi
}
