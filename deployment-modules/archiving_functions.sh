#!/bin/bash

# types available as the archive scheme
readonly ARCHIVE_SCHEME_FILES="files"
readonly ARCHIVE_SCHEME_SIZE="size"

HTDOCS_SUCCESS=true

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

    if [ "$ARCHIVE_SCHEME" = "$ARCHIVE_SCHEME_FILES" ]
    then
        archive_files
        run_backup "$backup_version"
    elif [ "$ARCHIVE_SCHEME" = "$ARCHIVE_SCHEME_SIZE" ]
    then
        archive_space "$backup_version"
        run_backup "$backup_version"
    else
        log_message true "Incorrect archive scheme supplied. Valid options are: space, files" "$MESSAGE_ERROR";
    fi
}

#
# archive_files:
# --------------
# Check whether the files limit has been hit.
#
function archive_files() {
    cd "$SITE_ROOT"/"$VERSIONS_DIR"

    while [ $(( $(find . -type f \( -iname "*.tgz" \) | wc -l) )) -gt "$ARCHIVE_LIMIT" ]
    do
        # find the oldest backup & remove that
        oldest=$(get_oldest_backup)
        rm "$oldest"
    done
}

function archive_space() {
    cd "$SITE_ROOT"/"$VERSIONS_DIR"
    local backup_version=$1
    # get size (in bytes) of directory
    local size=$(get_directory_size)
    # target size is in MB - convert to bytes
    local target_size=$(( $ARCHIVE_LIMIT * (1024 * 1024) ))

    # do a dry run of the archving process
    local archive_size=$(tar -czf - --exclude=assets "$SITE_ROOT"/"$HTDOCS_DIR" "$SITE_ROOT"/"$SQL_DUMPS_DIR"/"$MYSQL_DATABASE"-"$backup_version".sql | wc -c)

    remove_extraneousfiles "$archive_size" "$target_size"
}
#
# If the directory size is too large, keep removing archives from oldest -> newest
#
function remove_extraneousfiles() {
    let archive_size=$1
    let target_size=$2

    cd "$SITE_ROOT"/"$VERSIONS_DIR"

    while [ $(( $(get_directory_size) + $archive_size )) -gt $target_size ]
    do
        oldest=$(get_oldest_backup)
        rm "$oldest"
    done
}

function get_directory_size() {
    cd "$SITE_ROOT"/"$VERSIONS_DIR"
    local size=$(du -hs -B1 | sed 's/\([0-9\.GM]*\)\t\./\1/')
    echo "$size"
}

function get_oldest_backup() {
    cd "$SITE_ROOT"/"$VERSIONS_DIR"
    local oldest=$(find -type f -printf '%T+ %p\n' | grep -v '/\.' | sort | head -n 1 | sed 's/[^ ]* \.\///')
    echo "$oldest"
}


function run_backup() {
    local backup_version=$1

    cd "$SITE_ROOT" || exit

    if [ "$VERBOSE" = true ]
    then
        if ! (tar -czvf "$VERSION_NAME".tgz --exclude=assets "$HTDOCS_DIR" "$SQL_DUMPS_DIR"/"$MYSQL_DATABASE"-"$backup_version".sql)
        then
            HTDOCS_SUCCESS=false
        fi
    else
        if ! (tar -czf "$VERSIONS_DIR"/"$VERSION_NAME".tgz --exclude=assets "$HTDOCS_DIR" "$SQL_DUMPS_DIR"/"$MYSQL_DATABASE"-"$backup_version".sql)
        then
            HTDOCS_SUCCESS=false
        fi
    fi

    if [ "$HTDOCS_SUCCESS" = true ]
    then
        cd "$SITE_ROOT"/"$VERSIONS_DIR" || exit
        ln -sf "$(basename "$VERSION_NAME".tgz)" latest

        log_message true "$HTDOCS_DIR successfully archived" "$MESSAGE_SUCCESS";
    else
        log_message true "$HTDOCS_DIR archiving failed" "$MESSAGE_ERROR";
    fi

    # clean up sql
    rm -rf "${SITE_ROOT:?}"/"$SQL_DUMPS_DIR"
}
