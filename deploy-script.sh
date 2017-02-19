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

  -v Verbose - log all output
  -m Mode    - indicates whether we run bower & compser - 1 for "Lite" mode; 2 for "Full" mode
  -b Branch  - the branch to deploy from
  -h Help    - Display this help
  -t Theme   - Theme to use when running bower

END

while getopts vm:t:b:h option
do
    case "${option}"
    in
        v) VERBOSE=true;;
        m) CHOSEN_MODE=${OPTARG};;
        t) CHOSEN_THEME=${OPTARG};;
        b) CHOSEN_BRANCH=${OPTARG};;
        h) echo -e "$USAGE \n"; exit;;
    esac
done

#
# Script vars. Set these up prior to running.
#
SITE_ROOT=$(pwd)

ASSETS_DIR="$SITE_ROOT/assets"
DATABASE_VERSION=$(date "+%Y-%m-%d-%H_%M_%S")
DEFAULT_BRANCH="master"
DEFAULT_MODE="lite"
DEFAULT_THEME="default"
HTACCESS="$SITE_ROOT/htaccess"
HTDOCS_DIR="htdocs"
MYSQL_HOST="localhost"
MYSQL_USER="silverstripe"
MYSQL_PASSWORD="nU3asT52uwUb"
MYSQL_DATABASE="ss_wildeyes"
REPO_DIR="repo"
ROBOTS="$SITE_ROOT/robots.txt"
SQL_DUMPS_DIR="sql-dumps"
THEME_DIR="$SITE_ROOT/$REPO_DIR/themes"
VERSIONS_DIR="versions"
VERSION_NAME=$SITE_ROOT/$VERSIONS_DIR/$(date "+%Y-%m-%d-%H_%M_%S")

# ##########################################
# YOU SHOULDN'T HAVE TO EDIT BELOW HERE.
# ##########################################

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
source "$SITE_ROOT"/deployment-modules/git_functions.sh
git_fetch "$branch" "$SITE_ROOT"/"$REPO_DIR" "$VERBOSE"

#
# 2. Composer Update
# #########################################################
# shellcheck source=deployment-modules/composer_functions.sh
source "$SITE_ROOT"/deployment-modules/composer_functions.sh
composer_update "$MODE" "$VERBOSE"

#
# 3. Bower Update
# #########################################################
# shellcheck source=deployment-modules/bower_functions.sh
source "$SITE_ROOT"/deployment-modules/bower_functions.sh
bower_update "$MODE" "$VERBOSE" "$CHOSEN_THEME" "$THEME_DIR" "$SITE_ROOT"

#
# 4. MySQL Dump
# #########################################################
# shellcheck source=deployment-modules/mysqldump_functions.sh
source "$SITE_ROOT"/deployment-modules/mysqldump_functions.sh
mysql_dump_fn "$SITE_ROOT"/"$SQL_DUMPS_DIR" "$VERBOSE" "$MYSQL_HOST" "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_DATABASE" "$DATABASE_VERSION" "$SITE_ROOT"


#
# 5. Archive old htdocs dir & sql dump
# #########################################################
# shellcheck source=deployment-modules/archiving_functions.sh
source "$SITE_ROOT"/deployment-modules/archiving_functions.sh
archive_site

# #########################################################
# 6. Sync repo & htdocs
# #########################################################
cd "$SITE_ROOT" || exit
SYNC_SUCCESS=true
echo -e "\e[38;5;237mSynching the repo & $HTDOCS_DIR...\e[39m"

if [ "$VERBOSE" = true ]
then
    if ! (rsync -av --delete "$REPO_DIR"/ "$HTDOCS_DIR" --exclude .git* --exclude .gitignore --exclude .gitmodules --exclude readme.txt --exclude .htaccess --exclude robots.txt --exclude assets)
    then
        echo -e "\e[31mSynchronisation failed ✗\e[39m";
        SYNC_SUCCESS=false
    fi
else
    if ! (rsync -a --delete "$REPO_DIR"/ "$HTDOCS_DIR" --exclude .git* --exclude .gitignore --exclude .gitmodules --exclude readme.txt --exclude .htaccess --exclude robots.txt --exclude assets)
    then
        echo -e "\e[31mSynchronisation failed ✗\e[39m";
        SYNC_SUCCESS=false
    fi
fi

if [ "$SYNC_SUCCESS" = true ]
then
    echo -e "\e[32mSynchronisation successfully completed ✓\e[39m";
fi


# #########################################################
# 6. Run sake
# #########################################################
cd "$SITE_ROOT"/"$HTDOCS_DIR" || exit
SAKE_SUCCESS=true
echo -e "\e[38;5;237mSynching the database...\e[39m"
if [ "$VERBOSE" = true ]
then
    if [ "$MODE" == "full" ]
    then
        if ! (php framework/cli-script.php dev/build flush=all)
        then
            SAKE_SUCCESS=false
        fi
    else
        if ! (php framework/cli-script.php dev/build)
        then
            SAKE_SUCCESS=false
        fi
    fi
else
    if [ "$MODE" == "full" ]
    then
        if ! (php framework/cli-script.php dev/build flush=all &>/dev/null)
        then
            SAKE_SUCCESS=false
        fi
    else
        if ! (php framework/cli-script.php dev/build &>/dev/null)
        then
            SAKE_SUCCESS=false
        fi
    fi
fi

if [ "$SAKE_SUCCESS" = true ]
then
    echo -e "\e[32mdatabase sync successful ✓\e[39m"
else
    echo -e "\e[31mdatabase sync failed ✗\e[39m"
fi


# #########################################################
# END MODULES
# #########################################################


ln -sf ../assets .
cp "$HTACCESS" ./.htaccess
cp "$ROBOTS" ./robots.txt
cd "$SITE_ROOT" || exit

endTime=$(date +%s)
executionTime=$((endTime-startTime))

echo -e "-------------------------"
echo -e "\xF0\x9F\x8D\xBA \e[38;5;74mDeployment successful!\e[39m"
echo -e "\e[93mTime taken $executionTime seconds\e[39m"
exit 0
