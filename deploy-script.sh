#!/bin/bash

# ###########################################
# deploy-script.sh
# ----------------
# deployment script for salted herring silverstripe sites.
# Performs the following tasks:
# 1. Backup current db.
# 2. Checks out latest code.
# 3. Backs up current site.
# 4. Syncs with composer & bower
# 5. Updates db with current state.
# ###########################################

echo -en "\e[34m"
cat << EOF

                         :hh   dMs  -yo
                   \`.  \`NM/  /MN\`  hMs  .y/
                  +m-  sMh  \`NM/  /Mm\`  hMo
                 yMs  .NM-  sMd  \`mM/  /Mm\`
                :MN\`  hMs  \`so.  /Nd  \`mM/
                mM/  :MN\`             oMh
                Md   NM/  .           \`/.
                m-  oMd  \`mh\`
                \`  .NM-  oMd   /.
                   hMs  .MM-  oMd  \`:\`
                   hN\`  hMy  .NM-  oMd
                    \`  :MN.  yMy  \`NM-  oh.
                       -o/  :MN\`  yMy  .NM-
                            :h+  -MN\`  hMs  ..
                                 dM+  :MN\`  hm
                                 \`o   mM+  :MN
                    -/\`              +Md   mM+
                    mMo  \`\`         \`NM:  +Md
                   +Mm\`  dM+  -yh\`  yMy  .NM-
                  \`NM:  /Mm   dMo  -MN\`  yMy
                  yMh  \`NM/  +Mm   mM+  :Mm\`
                  -s.  sMh  \`NM:  +Mm\`  +-
                       +s.  +My  \`hh:


EOF
echo -e "\e[39mWelcome to the Salted Herring SilverStripe deploment system."
echo -e "\e[39m--------------------------------------"

#
# Usage output
# ------------
read -d '' USAGE << END
This script deploys SilverStripe based sites. It performs the following actions:

1. Backs up current database & files
2. Checks out the latest code
3. Optionally updates composer & bower
4. Synchronises the current site with the newly checked out code
5. Synchronises the databases

-----
USAGE:

./deployscript.sh [options]

  -v Verbose            - log all output
  -h Help               - Display this help
  -i Non-interactive    - Allow script to execute without waiting at each step.
  -c Config             - json file with default settings

 -------
 CONFIG:

 The json config file should look like so:

 {
     "apache_version": 2.4,
     "environment": "dev",
     "interactive": "true",
     "verbose": false,
     "root": "/var/www/silverstripe.domain/",
     "mysql": {
         "host": "localhost",
         "database_name": "ss_deployment",
         "username": "silverstripe",
         "password": "password"
     },
     "paths": {
         "htdocs": "htdocs",
         "versions": "versions",
         "repo": "repo",
         "sql_dumps": "sql-dumps",
         "themes": "themes"
     },
     "default": {
         "mode": 1,
         "theme": "default"
     },
     "logging": {
         "enabled": true,
         "directory": "/var/www/silverstripe.domain/logs",
         "filename": "silverstripe.domain.deployment.log"
     },
     "services": {
         "bower": true,
         "composer": true
     },
     "repository": {
         "mode": "branch",
         "target": "master"
     }
 }


END


#
# Arguments:
# ----------
readonly startTime=$(date "+%s")
readonly LOGGING_DATE=$(date "+%d-%m-%Y %H:%m:%S")
readonly SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
readonly DATABASE_VERSION=$(date "+%Y-%m-%d-%H_%M_%S")

# shellcheck source=deployment-modules/logging.sh
source "$SCRIPT_PATH"/deployment-modules/logging.sh

INTERACTIVE=true
VERBOSE=false

CHOSEN_MODE=0
CHOSEN_REPO_MODE=0
CHOSEN_REPO_TARGET=0
CHOSEN_THEME=false
CHOSEN_ENV=false
CHOSEN_CONFIG=false
CHOSEN_SITE_ROOT=false

while getopts ic:vh option
do
    case "${option}"
    in
        c) CHOSEN_CONFIG=${OPTARG};;
        v) VERBOSE=true;;
        i) INTERACTIVE=false;;
        h) echo -e "$USAGE \n"; exit;;
    esac
done

if [ "$CHOSEN_CONFIG" = false ]
then
    log_message true "You need to supply a vlid configuration file via the -c flag" "$MESSAGE_ERROR"
    exit
fi



#
# Script vars. Set these up prior to running.
#
if [ ! "$CHOSEN_SITE_ROOT" = false ]
then
    SITE_ROOT="$CHOSEN_SITE_ROOT"
else
    SITE_ROOT=$(pwd)
fi

#
# Process options:
# ----------------

# shellcheck source=deployment-modules/process_options.sh
source "$SCRIPT_PATH"/deployment-modules/process_options.sh


# Don't execute this script inside the same directory as deploy-script.sh
if [ "$SITE_ROOT" = "$SCRIPT_PATH" ]
then
    log_message true "WARNING - you need to run this script from outside this directory" "$MESSAGE_ERROR"
    exit
fi

# #########################################################

#
# Load modules:
# -------------

# shellcheck source=deployment-modules/utilities.sh
source "$SCRIPT_PATH"/deployment-modules/utilities.sh

# shellcheck source=deployment-modules/archiving_functions.sh
source "$SCRIPT_PATH"/deployment-modules/archiving_functions.sh

# shellcheck source=deployment-modules/bower_functions.sh
source "$SCRIPT_PATH"/deployment-modules/bower_functions.sh

# shellcheck source=deployment-modules/composer_functions.sh
source "$SCRIPT_PATH"/deployment-modules/composer_functions.sh

# shellcheck source=deployment-modules/git_functions.sh
source "$SCRIPT_PATH"/deployment-modules/git_functions.sh

# shellcheck source=deployment-modules/maintenance_functions.sh
source "$SCRIPT_PATH"/deployment-modules/maintenance_functions.sh

# shellcheck source=deployment-modules/mysqldump_functions.sh
source "$SCRIPT_PATH"/deployment-modules/mysqldump_functions.sh

# shellcheck source=deployment-modules/sake_functions.sh
source "$SCRIPT_PATH"/deployment-modules/sake_functions.sh

# shellcheck source=deployment-modules/sync_functions.sh
source "$SCRIPT_PATH"/deployment-modules/sync_functions.sh

# #########################################################

log_message true "Deployment started" "$MESSAGE_INFO" true;




# #########################################################
# Choose mode & branch
# #########################################################

if [ "$CHOSEN_MODE" = 0 ]
then
    echo -e "Which environment would you like to deploy? \e[1m[Lite]\e[22m"
    echo "1. Lite (only file updates)"
    echo "2. Full (file, composer, and bower)"
    read -p "" userchoice

    if [[ -z "$userchoice" ]]; then
       echo -e "   • Lite mode chosen"
       MODE=$DEFAULT_MODE
    else
        case $userchoice in
        1) echo -e "   • Mode chosen: \e[1mLite\e[22m"
            MODE="lite"
            ;;
        2) echo -e "   • Mode chosen: \e[1mFull\e[22m"
            MODE="full"
            ;;
        *) log_message true "Incorrect mode ($userchoice) supplied" "$MESSAGE_ERROR";
            exit
            ;;
        esac
    fi
else
    case $CHOSEN_MODE in
    1) echo -e "   • Mode chosen: \e[1mLite\e[22m"
        MODE="lite"
        ;;
    2) echo -e "   • Mode chosen: \e[1mFull\e[22m"
        MODE="full"
        ;;
    *) log_message true "Incorrect mode ($CHOSEN_MODE) supplied" "$MESSAGE_ERROR";
        exit
        ;;
    esac
fi

get_git_target

#
# Check the chosen environment.
#
if [ ! "$CHOSEN_ENV" = false ]
then
    ENV=$CHOSEN_ENV
    echo -e "   • Environment: \e[1m$CHOSEN_ENV\e[22m"
fi

#
# Check to see if the versions directory exists
#
if [ ! -d $SITE_ROOT/$VERSIONS_DIR ]
then
    mkdir -p $SITE_ROOT/$VERSIONS_DIR
fi


#
# If the chosen mode is full - then ask for the theme directory to
# run bower from.
#
if [ "$MODE" = full ]
then
    if [ "$CHOSEN_THEME" = false ]
    then
        echo -e "\n"
        echo -e "Which theme should bower be run from? \e[1m[$DEFAULT_THEME]\e[22m"
        read -p "" theme

        if [[ -z "$theme" ]]; then
            CHOSEN_THEME=$DEFAULT_THEME
        else
            CHOSEN_THEME=$theme
        fi

        echo -e "   • Chosen theme: \e[1m$CHOSEN_THEME\e[22m"
    else
        echo -e "   • Chosen theme: \e[1m$CHOSEN_THEME\e[22m"
    fi
fi

echo -e "\e[39m--------------------------------------"

# #########################################################
# MODULES
# ---------------------------------------------------------
# Load & run all available modules.
# #########################################################

#
# 1. Git fetch
# ------------
git_fetch "$CHOSEN_REPO_MODE" "$CHOSEN_REPO_TARGET"
interactive

#
# 2. Composer Update
# ------------------
composer_update
interactive

#
# 3. Bower Update
# ---------------
bower_update
interactive

#
# 4. MySQL Dump
# -------------
mysql_dump_fn "$DATABASE_VERSION"
interactive


#
# 5. Archive old htdocs dir & sql dump
# ------------------------------------
archive_site "$DATABASE_VERSION"
interactive

#
# 6. Sync repo & htdocs
# ---------------------
sync_files
interactive

#
# 7. Enable Maintenance Mode
# --------------------------
maintenance_mode on
interactive

#
# 8. Run sake
# -----------
sake_build
interactive

#
# 9. Disable Maintenance Mode
# ---------------------------
maintenance_mode off
interactive


# #########################################################
# END MODULES
# #########################################################



# #########################################################
# FINISH UP.
# #########################################################
if [ -d "$SITE_ROOT"/"$HTDOCS_DIR"/assets ]
then
    rm -rf "$SITE_ROOT"/"$HTDOCS_DIR"/assets
fi

ln -sf ../assets .

# Set up htaccess & robots based on env.
if [ "$ENV" = "live" ]
then
    if [ "$APACHE_VERSION" = 2.4 ]
    then
        cp "$SCRIPT_PATH"/resources/apache-2.4/.live-htaccess "$SITE_ROOT"/"$HTDOCS_DIR"/.htaccess
    else
        cp "$SCRIPT_PATH"/resources/apache-2.2/.live-htaccess "$SITE_ROOT"/"$HTDOCS_DIR"/.htaccess
    fi

    cp "$SCRIPT_PATH"/resources/robots/live-robots.txt "$SITE_ROOT"/"$HTDOCS_DIR"/robots.txt
else
    if [ "$APACHE_VERSION" = 2.4 ]
    then
        cp "$SCRIPT_PATH"/resources/apache-2.4/.dev-htaccess "$SITE_ROOT"/"$HTDOCS_DIR"/.htaccess
    else
        cp "$SCRIPT_PATH"/resources/apache-2.2/.dev-htaccess "$SITE_ROOT"/"$HTDOCS_DIR"/.htaccess
    fi

    cp "$SCRIPT_PATH"/resources/robots/dev-robots.txt "$SITE_ROOT"/"$HTDOCS_DIR"/robots.txt
fi

cd "$SITE_ROOT" || exit

endTime=$(date +%s)
executionTime=$((endTime-startTime))

echo -e "-------------------------"
log_message true "Deployment successful!" "$MESSAGE_RESULT";
log_message true "Time taken $executionTime seconds" "$MESSAGE_STATS";
exit 0
