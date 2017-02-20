#!/bin/bash

#
# PROCESS OPTIONS:
# ----------------
# Process the options passed into the script.

# Defaults
APACHE_VERSION=2.4
DEFAULT_BRANCH="master"
DEFAULT_MODE="lite"
DEFAULT_THEME="default"
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

# If a config file is passed in, override the arguments
if [ ! "$CHOSEN_CONFIG" = false ]
then
    # first, extract the config values
    root_config=$(cat $CHOSEN_CONFIG | jq '. | .root' | tr -d '"')
    env_config=$(cat $CHOSEN_CONFIG | jq '. | .environment' | tr -d '"')
    apache_config=$(cat $CHOSEN_CONFIG | jq '. | .apache_version')
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

    # then assign to the parameters
    SITE_ROOT="$root_config"
    ENV="$env_config"
    APACHE_VERSION="$apache_config"
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

    # Override cli arguments
    CHOSEN_MODE="$default_mode_config"
    CHOSEN_BRANCH="$default_branch_config"
    CHOSEN_ENV="$env_config"
    CHOSEN_THEME="$default_theme_config"
fi

# Vars that possibly need to be re-evaluated after processing
ASSETS_DIR="$SITE_ROOT/assets"
VERSION_NAME=$SITE_ROOT/$VERSIONS_DIR/$(date "+%Y-%m-%d-%H_%M_%S")
