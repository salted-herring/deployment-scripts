#!/bin/bash

readonly MESSAGE_INFO=1
readonly MESSAGE_ERROR=2
readonly MESSAGE_SUCCESS=3
readonly MESSAGE_RESULT=4
readonly MESSAGE_STATS=5

readonly OUTPUT_MESSAGE_INFO="\e[38;5;237m%s\e[39m"
readonly OUTPUT_MESSAGE_ERROR="\e[31m%s ✗\e[39m"
readonly OUTPUT_MESSAGE_SUCCESS="\e[32m%s ✓\e[39m"
readonly OUTPUT_MESSAGE_RESULT_END="\xF0\x9F\x8D\xBA \e[38;5;74m%s\e[39m"
readonly OUTPUT_MESSAGE_STATS="\e[93m%s\e[39m"

readonly LOG_FORMAT="%s\t%s\t%s" # date type message
readonly LOG_TYPES=("" "INFO" "ERROR" "SUCCESS" "RESULT" "STATS")

#
# log_message:
# -------------
# Display message & optionally log to file
#
# assumes LOGGING_ENABLED, LOGGING_DIRECTORY, LOGGING_FILENAME & LOGGING_DATE are available.
#
# @arg log - whether to log as well as display the message
# @arg message - the message to show/log
# @arg messageType - one of the following constants
# @arg logOnly - only log, don't message
#
function log_message() {
    local log=$1
    local message=$2
    local messageType=$3
    local logOnly=$4

    local formattedMessage=""

    if [ -z "$logOnly" ]
    then
        logOnly=false
    fi

    # set up message
    if [ ! -z "$message" ] && [ ! -z "$messageType" ] && [ "$logOnly" = false ]
    then
        case $messageType in
        1) formattedMessage=$(printf "$OUTPUT_MESSAGE_INFO" "$message");;
        2) formattedMessage=$(printf "$OUTPUT_MESSAGE_ERROR" "$message");;
        3) formattedMessage=$(printf "$OUTPUT_MESSAGE_SUCCESS" "$message");;
        4) formattedMessage=$(printf "$OUTPUT_MESSAGE_RESULT_END" "$message");;
        5) formattedMessage=$(printf "$OUTPUT_MESSAGE_STATS" "$message");;
        esac

        echo -e "$formattedMessage"
    fi

    # log error
    if [ ! -z "$message" ] && [ ! -z "$messageType" ] && [ ! -z "$log" ] && [ "$LOGGING_ENABLED" = true ]
    then
        if [ "$log" = true ]
        then
            formattedMessage=$(printf "$LOG_FORMAT" "$LOGGING_DATE" "${LOG_TYPES[$messageType]}" "$message")
            echo "$formattedMessage" >> "$LOGGING_DIRECTORY"/"$LOGGING_FILENAME"
        fi
    fi
}
