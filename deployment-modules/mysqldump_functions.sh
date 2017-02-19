#!/bin/bash

#
# mysql_dump:
# -------------
# MySQL dump
#
# @arg path - where the sql dump is stored (temporarily)
# @arg verbose - show/hide output
# @arg mysql_host
# @arg mysql_user
# @arg mysql_password
# @arg mysql_database
# @arg database_version - a unique string to identify the dump (likely a timestamp)
# @arg siteroot - bash path to reurn to.
#

MYSQL_SUCCESS=true

function mysql_dump_fn() {
    local MYSQL_PATH=$1
    local VERBOSE=$2
    local MYSQL_HOST=$3
    local MYSQL_USER=$4
    local MYSQL_PASSWORD=$5
    local MYSQL_DATABASE=$6
    local DATABASE_VERSION=$7
    local SITEROOT=$8

    echo -e "\e[38;5;237mStarting MySQL dump...\e[39m";
    /bin/mkdir -p "$MYSQL_PATH"
    cd "$MYSQL_PATH" || exit

    if [ "$VERBOSE" = true ]
    then
        if ! (/usr/bin/mysqldump -v -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "$MYSQL_DATABASE"-"$DATABASE_VERSION".sql)
        then
            MYSQL_SUCCESS=false
        fi
    else
        if ! (/usr/bin/mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "$MYSQL_DATABASE"-"$DATABASE_VERSION".sql)
        then
            MYSQL_SUCCESS=false
        fi
    fi

    if [ "$MYSQL_SUCCESS" = true ]
    then
        echo -e "\e[32mMySQL dump successful ✓\e[39m"
    else
        echo -e "\e[31mMySQL dump failed ✗\e[39m";
    fi
}
