#!/bin/bash

startTime=$(date +%s)
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

# ###########################################
# Arguments:
# ----------
# The script accepts the following arguments:
# --v, --verbose - show all output.
# ###########################################
VERBOSE=false
CHOSEN_MODE=0
CHOSEN_BRANCH=0
CHOSEN_THEME=false
CHOSEN_ENV=false
CHOSEN_CONFIG=false

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

  -v Verbose     - log all output
  -m Mode        - indicates whether we run bower & compser - 1 for "Lite" mode; 2 for "Full" mode
  -b Branch      - the branch to deploy from
  -e Environment - The SilverStripe environment (e.g. "dev" or "live")
  -h Help        - Display this help
  -t Theme       - Theme to use when running bower
  -c Config      - json file with default settings

END

while getopts c:vm:e:t:b:h: option
do
    case "${option}"
    in
        c) CHOSEN_CONFIG=${OPTARG};;
        v) VERBOSE=true;;
        m) CHOSEN_MODE=${OPTARG};;
        e) CHOSEN_ENV=${OPTARG};;
        t) CHOSEN_THEME=${OPTARG};;
        b) CHOSEN_BRANCH=${OPTARG};;
        h) echo -e "$USAGE \n"; exit;;
    esac
done

#
# Script vars. Set these up prior to running.
#
SITE_ROOT=$(pwd)
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ASSETS_DIR="$SITE_ROOT/assets"
DATABASE_VERSION=$(date "+%Y-%m-%d-%H_%M_%S")


# Can't execute this script inside the same directory as deploy-script.sh
if [ "$SITE_ROOT" = "$SCRIPT_PATH" ]
then
    echo -e "\e[31mWARNING - you need to run this script from outside this directory.\e[39m"
    exit
fi

# shellcheck source=deployment-modules/process_options.sh
source "$SCRIPT_PATH"/deployment-modules/process_options.sh

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
       echo -e "\t• Lite mode chosen"
       MODE=$DEFAULT_MODE
    else
        case $userchoice in
        1) echo -e "\t• Mode chosen: \e[1mLite\e[22m"
            MODE="lite"
            ;;
        2) echo -e "\t• Mode chosen: \e[1mFull\e[22m"
            MODE="full"
            ;;
        *) echo -e "\e[31mIncorrect mode chosen. Exiting ✗\e[39m"
            exit
            ;;
        esac
    fi
else
    case $CHOSEN_MODE in
    1) echo -e "\t• Mode chosen: \e[1mLite\e[22m"
        MODE="lite"
        ;;
    2) echo -e "\t• Mode chosen: \e[1mFull\e[22m"
        MODE="full"
        ;;
    *) echo -e "\e[31mIncorrect mode chosen. Exiting ✗\e[39m"
        exit
        ;;
    esac
fi


if [ "$CHOSEN_BRANCH" = 0 ]
then
    echo -e "\n"
    echo -e "Which branch should we deploy from?: \e[1m[$DEFAULT_BRANCH]\e[22m "
    read branch
else
    branch=$CHOSEN_BRANCH
fi


# check branch exists
cd "$SITE_ROOT/$REPO_DIR" || exit
if ! (git rev-parse --verify "$branch" &>/dev/null)
then
    echo -e "\e[31mCan't find the $branch branch in the current repository. You may want to perform a git fetch before running this again. \e[39m"
    exit
fi



if [[ -z "$branch" ]]; then
   echo -e "\t• Deployment branch: \e[1m$DEFAULT_BRANCH\e[22m"
   branch=$DEFAULT_BRANCH
else
   echo -e "\t• Deployment branch: \e[1m$branch\e[22m"
fi

#
# Check the chosen environment.
#
if [ ! "$CHOSEN_ENV" = false ]
then
    ENV=$CHOSEN_ENV
    echo -e "\t• Environment: \e[1m$CHOSEN_ENV\e[22m"
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

        echo -e "\t• Chosen theme: \e[1m$CHOSEN_THEME\e[22m"
    else
        echo -e "\t• Chosen theme: \e[1m$CHOSEN_THEME\e[22m"
    fi
fi

echo -e "\n"


# #########################################################
# MODULES
# ---------------------------------------------------------
# Load & run all available modules.
# #########################################################



#
# 1. Git fetch
# #########################################################
# shellcheck source=deployment-modules/git_functions.sh
source "$SCRIPT_PATH"/deployment-modules/git_functions.sh
git_fetch "$branch" "$SITE_ROOT"/"$REPO_DIR" "$VERBOSE"

#
# 2. Composer Update
# #########################################################
# shellcheck source=deployment-modules/composer_functions.sh
source "$SCRIPT_PATH"/deployment-modules/composer_functions.sh
composer_update "$MODE" "$VERBOSE"

#
# 3. Bower Update
# #########################################################
# shellcheck source=deployment-modules/bower_functions.sh
source "$SCRIPT_PATH"/deployment-modules/bower_functions.sh
bower_update "$MODE" "$VERBOSE" "$CHOSEN_THEME" "$THEME_DIR" "$SITE_ROOT"

#
# 4. MySQL Dump
# #########################################################
# shellcheck source=deployment-modules/mysqldump_functions.sh
source "$SCRIPT_PATH"/deployment-modules/mysqldump_functions.sh
mysql_dump_fn "$SITE_ROOT"/"$SQL_DUMPS_DIR" "$VERBOSE" "$MYSQL_HOST" "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_DATABASE" "$DATABASE_VERSION" "$SITE_ROOT"


#
# 5. Archive old htdocs dir & sql dump
# #########################################################
# shellcheck source=deployment-modules/archiving_functions.sh
source "$SCRIPT_PATH"/deployment-modules/archiving_functions.sh
archive_site "$SITE_ROOT" "$HTDOCS_DIR" "$VERBOSE" "$VERSION_NAME" "$SQL_DUMPS_DIR" "$MYSQL_DATABASE" "$DATABASE_VERSION" "$VERSIONS_DIR"

#
# 6. Sync repo & htdocs
# #########################################################
# shellcheck source=deployment-modules/sync_functions.sh
source "$SCRIPT_PATH"/deployment-modules/sync_functions.sh
sync_files "$SITE_ROOT" "$VERBOSE" "$HTDOCS_DIR" "$REPO_DIR"

#
# 7. Enable Maintenance Mode
# #########################################################
# shellcheck source=deployment-modules/maintenance_functions.sh
source "$SCRIPT_PATH"/deployment-modules/maintenance_functions.sh
maintenance_mode "$SITE_ROOT" "$HTDOCS_DIR" "$VERBOSE" on

#
# 8. Run sake
# #########################################################
# shellcheck source=deployment-modules/sake_functions.sh
source "$SCRIPT_PATH"/deployment-modules/sake_functions.sh
sake_build "$SITE_ROOT" "$HTDOCS_DIR" "$VERBOSE" "$MODE"

#
# 9. Disable Maintenance Mode
# #########################################################
# shellcheck source=deployment-modules/maintenance_functions.sh
source "$SCRIPT_PATH"/deployment-modules/maintenance_functions.sh
maintenance_mode "$SITE_ROOT" "$HTDOCS_DIR" "$VERBOSE" off


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
echo -e "\xF0\x9F\x8D\xBA \e[38;5;74mDeployment successful!\e[39m"
echo -e "\e[93mTime taken $executionTime seconds\e[39m"
exit 0
