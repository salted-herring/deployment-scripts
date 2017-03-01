#!/bin/bash

#
# PROCESS OPTIONS:
# ----------------
# Process the options passed into the script.

# Defaults
APACHE_VERSION=2.4
BOWER=true
COMPOSER=true
DEFAULT_BRANCH="master"
DEFAULT_TAG="stable"
DEFAULT_MODE="lite"
DEFAULT_THEME="default"
DEFAULT_REPO_MODE="branch"
DEFAULT_REPO_TARGET="master"
ENV="dev"
HTDOCS_DIR="htdocs"
MYSQL_HOST="localhost"
MYSQL_USER="silverstripe"
MYSQL_PASSWORD="nU3asT52uwUb"
MYSQL_DATABASE="ss_wildeyes"
REPO_DIR="repo"
SQL_DUMPS_DIR="sql-dumps"
THEME_DIR="$SITE_ROOT/$REPO_DIR/themes"
VERSIONS_DIR="versions"
LOGGING_ENABLED=false
LOGGING_DIRECTORY="."
LOGGING_FILENAME="silverstripe.domain.deployment.log"
ARCHIVE_SCHEME="files"
ARCHIVE_LIMIT=8

# If a config file is passed in, override the arguments
if [ ! "$CHOSEN_CONFIG" = false ]
then
    # first, extract the config values
    archive_scheme=$(cat $CHOSEN_CONFIG | jq '. | .archiving.scheme' | tr -d '"')
    archive_limit=$(cat $CHOSEN_CONFIG | jq '. | .archiving.limit' | tr -d '"')
    root_config=$(cat $CHOSEN_CONFIG | jq '. | .root' | tr -d '"')
    env_config=$(cat $CHOSEN_CONFIG | jq '. | .environment' | tr -d '"')
    apache_config=$(cat $CHOSEN_CONFIG | jq '. | .apache_version')
    bower_config=$(cat $CHOSEN_CONFIG | jq '. | .services.bower')
    composer_config=$(cat $CHOSEN_CONFIG | jq '. | .services.composer')
    default_branch_config=$(cat $CHOSEN_CONFIG | jq '. | .default.branch' | tr -d '"')
    default_mode_config=$(cat $CHOSEN_CONFIG | jq '. | .default.mode')
    default_theme_config=$(cat $CHOSEN_CONFIG | jq '. | .default.theme' | tr -d '"')
    htdocs_dir_config=$(cat $CHOSEN_CONFIG | jq '. | .paths.htdocs' | tr -d '"')
    repo_dir_config=$(cat $CHOSEN_CONFIG | jq '. | .paths.repo' | tr -d '"')
    sql_dir_config=$(cat $CHOSEN_CONFIG | jq '. | .paths.sql_dumps' | tr -d '"')
    versions_dir_config=$(cat $CHOSEN_CONFIG | jq '. | .paths.versions' | tr -d '"')
    themes_dir_config=$(cat $CHOSEN_CONFIG | jq '. | .paths.themes' | tr -d '"')
    mysql_host_config=$(cat $CHOSEN_CONFIG | jq '. | .mysql.host' | tr -d '"')
    mysql_user_config=$(cat $CHOSEN_CONFIG | jq '. | .mysql.username' | tr -d '"')
    mysql_password_config=$(cat $CHOSEN_CONFIG | jq '. | .mysql.password' | tr -d '"')
    mysql_database_config=$(cat $CHOSEN_CONFIG | jq '. | .mysql.database_name' | tr -d '"')
    interactive_config=$(cat $CHOSEN_CONFIG | jq '. | .interactive' | tr -d '"')
    verbose_config=$(cat $CHOSEN_CONFIG | jq '. | .verbose' | tr -d '"')
    logging_enabled=$(cat $CHOSEN_CONFIG | jq '. | .logging.enabled' | tr -d '"')
    logging_dir=$(cat $CHOSEN_CONFIG | jq '. | .logging.directory' | tr -d '"')
    logging_filename=$(cat $CHOSEN_CONFIG | jq '. | .logging.filename' | tr -d '"')

    repository_mode=$(cat $CHOSEN_CONFIG | jq '. | .repository.mode' | tr -d '"')
    repository_target=$(cat $CHOSEN_CONFIG | jq '. | .repository.target' | tr -d '"')

    # then assign to the parameters
    ARCHIVE_SCHEME="$archive_scheme"
    ARCHIVE_LIMIT="$archive_limit"
    SITE_ROOT="$root_config"
    ENV="$env_config"
    APACHE_VERSION="$apache_config"
    BOWER="$bower_config"
    COMPOSER="$composer_config"
    DEFAULT_BRANCH="$default_branch_config"
    DEFAULT_MODE="$default_mode_config"
    DEFAULT_THEME="$default_theme_config"
    HTDOCS_DIR="$htdocs_dir_config"
    REPO_DIR="$repo_dir_config"
    SQL_DUMPS_DIR="$sql_dir_config"
    THEME_DIR="$SITE_ROOT/$REPO_DIR/$themes_dir_config"
    VERSIONS_DIR="$versions_dir_config"
    MYSQL_HOST="$mysql_host_config"
    MYSQL_USER="$mysql_user_config"
    MYSQL_PASSWORD="$mysql_password_config"
    MYSQL_DATABASE="$mysql_database_config"
    INTERACTIVE="$interactive_config"
    VERBOSE="$verbose_config"
    LOGGING_ENABLED="$logging_enabled"
    LOGGING_DIRECTORY="$logging_dir"
    LOGGING_FILENAME="$logging_filename"

    DEFAULT_REPO_MODE="$repository_mode"
    DEFAULT_REPO_TARGET="$repository_target"

    # Override chosen arguments
    CHOSEN_MODE="$default_mode_config"
    CHOSEN_ENV="$env_config"
    CHOSEN_THEME="$default_theme_config"
    CHOSEN_REPO_MODE="$repository_mode"
    CHOSEN_REPO_TARGET="$repository_target"

    # logging
    if [ "$LOGGING_ENABLED" = true ]
    then
        if [ ! -d "$LOGGING_DIRECTORY" ]
        then
            mkdir -p $LOGGING_DIRECTORY
        fi

        if [ ! -f "$LOGGING_DIRECTORY"/"$LOGGING_FILENAME" ]
        then
            touch "$LOGGING_DIRECTORY"/"$LOGGING_FILENAME"
        fi
    fi
fi

# Vars that possibly need to be re-evaluated after processing
ASSETS_DIR="$SITE_ROOT/assets"
VERSION_NAME="$SITE_ROOT"/"$VERSIONS_DIR"/"$DATABASE_VERSION"
