#!/bin/bash
echo -en "\e[92m"
cat << EOF


  d888888o.           .8.          8 8888   8888888 8888888888 \`8.\`8888.      ,8'
 .\`8888:' \`88.        .888.         8 8888         8 8888        \`8.\`8888.    ,8'
 8.\`8888.   Y8       :88888.        8 8888         8 8888         \`8.\`8888.  ,8'
 \`8.\`8888.          . \`88888.       8 8888         8 8888          \`8.\`8888.,8'
  \`8.\`8888.        .8. \`88888.      8 8888         8 8888           \`8.\`88888'
   \`8.\`8888.      .8\`8. \`88888.     8 8888         8 8888            \`8. 8888
    \`8.\`8888.    .8' \`8. \`88888.    8 8888         8 8888             \`8 8888
8b   \`8.\`8888.  .8'   \`8. \`88888.   8 8888         8 8888              8 8888
\`8b.  ;8.\`8888 .888888888. \`88888.  8 8888         8 8888              8 8888
 \`Y8888P ,88P'.8'       \`8. \`88888. 8 888888888888 8 8888              8 8888


EOF
echo -e "\e[39mWelcome to the Salty deploment system."
echo -e "\e[39m--------------------------------------"

# ###########################################
# deploy-script.sh
# ----------------
# deployment script for salted herring sites.
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
while test $# -gt 0
do
    case "$1" in
        --verbose) VERBOSE=true
            ;;
        --*) echo "bad option $1"
            ;;
        *) echo "argument $1"
            ;;
    esac
    shift
done

#
# Script vars. Set these up prior to running.
#
SITE_ROOT=$(pwd)
DEFAULT_BRANCH="develop"
HTDOCS_DIR="public_html"
SQL_DUMPS_DIR="sql-dumps"
REPO_DIR="repo"
VERSIONS_DIR="versions"
MYSQL_HOST="localhost"
MYSQL_USER="silverstripe"
MYSQL_PASSWORD="nU3asT52uwUb"
MYSQL_DATABASE="ss_wildeyes"
DATABASE_VERSION=$(date "+%Y-%m-%d-%H_%M_%S")
VERSION_NAME=$SITE_ROOT/$VERSIONS_DIR/$(date "+%Y-%m-%d-%H_%M_%S")
HTACCESS="$SITE_ROOT/htaccess"
ROBOTS="$SITE_ROOT/robots.txt"
ASSETS_DIR="$SITE_ROOT/assets"

previous=""
# ##########################################
# YOU SHOULDN'T HAVE TO EDIT BELOW HERE.
# ##########################################

echo "Which environment would you like to deploy?"
echo "1. Lite (only file updates)"
echo "2. Full (file, composer, and bower)"
read userchoice

case $userchoice in
1) echo "Lite mode chosen"
    MODE="lite"
    ;;
2) echo "Full mode chosen"
    MODE="full"
    ;;
*) echo "Default to development"
    MODE="lite"
    ;;
esac

read -p "Which branch should we deploy from?: [$DEFAULT_BRANCH] " branch

if [[ -z "$branch" ]]; then
   printf '%s\n' "Deployment branch: $DEFAULT_BRANCH"
   branch=$DEFAULT_BRANCH
else
   printf 'Deployment branch: %s\n' "$branch"
fi

# #########################################################
# Find the latest version & link it as the previous version
# (ensuring rolling back is straight forward)
# #########################################################

if [ -L $SITE_ROOT/$VERSIONS_DIR/latest ]; then
    cd $SITE_ROOT/$VERSIONS_DIR/latest
    previous=`pwd -P`

    if [ -L $SITE_ROOT/$VERSIONS_DIR/latest ]; then
        rm $SITE_ROOT/$VERSIONS_DIR/previous
    fi

    ln -sf $previous $SITE_ROOT/$VERSIONS_DIR/previous
    #rm $SITE_ROOT/$VERSIONS_DIR/latest
fi

cd $SITE_ROOT

# #########################################################
# 1. MySQL Dump
# #########################################################
mkdir -p $SITE_ROOT/$SQL_DUMPS_DIR
if [ "$VERBOSE" = true ]
then
    echo -e "\e[90mStarting MySQL dump\e[39m";
    mysqldump -v -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $SQL_DUMPS_DIR/$MYSQL_DATABASE-$DATABASE_VERSION.sql
else
    mysqldump -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $SQL_DUMPS_DIR/$MYSQL_DATABASE-$DATABASE_VERSION.sql
fi


##
# Create symlink to latest dump
##
if [ -L $SITE_ROOT/$SQL_DUMPS_DIR/latest ]; then
    realPath=`realpath $SITE_ROOT/$SQL_DUMPS_DIR/latest`
    ln -sf $realPath $SITE_ROOT/$SQL_DUMPS_DIR/previous
    rm $SITE_ROOT/$SQL_DUMPS_DIR/latest
fi

ln -sf $SITE_ROOT/$SQL_DUMPS_DIR/$MYSQL_DATABASE-$DATABASE_VERSION.sql $SITE_ROOT/$SQL_DUMPS_DIR/latest

if [ $? -eq 0 ]; then echo -e "\e[32mMySQL dump successful ✓\e[39m"; fi

cd $SITE_ROOT/$REPO_DIR

# #########################################################



# #########################################################
# 2. Git fetch
# #########################################################
GIT_SUCCESS=true
#
# Display git failed message. Pass an arg to display - e.g.:
#   git_fail "fetch" - gives "fetch failed ✗"
#
function git_fail() {
    echo -e "\e[31mRepository retrieval failed ✗\e[39m";

    if ! [ -z "$1" ]
    then
        echo -e "\e[31m$1 failed ✗\e[39m";
    fi

    echo -e "\e[31mDeployment failed ✗\e[39m";
    exit 1
}

if [ "$VERBOSE" = true ]
then
    if ! (git fetch --all)
    then
        GIT_SUCCESS=false;
        git_fail "fetch";
    fi
    if ! (git checkout $branch) then
        GIT_SUCCESS=false
        git_fail "checkout $branch";
    fi
    if ! (git pull origin $branch) then
        GIT_SUCCESS=false
        git_fail "pull $branch";
    fi
else
    if ! (git fetch --all &> /dev/null) then
        GIT_SUCCESS=false;
        git_fail "fetch";
    fi
    if ! (git checkout --quiet $branch) then
        GIT_SUCCESS=false
        git_fail "checkout $branch";
    fi
    if ! (git pull --quiet origin $branch) then
        GIT_SUCCESS=false
        git_fail "pull $branch";
    fi
fi

if [ "$GIT_SUCCESS" = true ]
then
    echo -e "\e[32mGit successfully pulled from $branch branch ✓\e[39m";
else
    git_fail
fi

# #########################################################


if [ $MODE == "full" ]; then
    echo -e "\e[32mUpdating composer... \e[39m";
    composer update;
    echo -e "\e[32mComposer updated. Now bower... \e[39m";
    cd themes/default;
    bower update;
    echo -e "\e[32mBower updated.\e[39m";
fi

if [ -t 1 ]; then echo -e "\e[32mPreparing to depreciate the current public_html\e[39m"; fi
cd $SITE_ROOT
cp -rf $SITE_ROOT/$REPO_DIR $VERSION_NAME

rm $SITE_ROOT/$VERSIONS_DIR/latest
ln -s $VERSION_NAME $SITE_ROOT/$VERSIONS_DIR/latest


if [ -t 1 ]; then echo -e "\e[32mCurrent public_html has been depreciated\e[39m"; fi
rm -rf $SITE_ROOT/$HTDOCS_DIR;
ln -s $VERSION_NAME $SITE_ROOT/$HTDOCS_DIR
cd $SITE_ROOT/$HTDOCS_DIR
if [ -t 1 ]; then echo -e "\e[32mCreating symbolic link to assets directory...\e[39m"; fi
rm -rf $SITE_ROOT/$HTDOCS_DIR/assets
ln -s $ASSETS_DIR .
if [ -t 1 ]; then echo -e "\e[32mRefreshing database\e[39m"; fi

# #########################
# Archive previous versions
# #########################
cd $SITE_ROOT/$VERSIONS_DIR

if [ -L $SITE_ROOT/$SQL_DUMPS_DIR/previous ]; then
    realPath=`realpath $SITE_ROOT/$SQL_DUMPS_DIR/previous`
    dateName=part1=`dirname $realPath`
    tar -czvf $dateName.tgz $realPath
    rm -rf $realPath
    ln -s $dateName.tgz $SITE_ROOT/$SQL_DUMPS_DIR/previous
fi


cd $SITE_ROOT/$HTDOCS_DIR

if [ $MODE == "full" ];
then
    sake dev/build flush=all;
else
    sake dev/build;
fi
if [ -t 1 ]; then echo -e "\e[32mDatabase refreshed\e[39m"; fi
if [ -t 1 ]; then echo -e "\e[32mCleaning...\e[39m"; fi
rm -rf .git*
rm .editorconfig
cp $HTACCESS ./.htaccess
cp $ROBOTS ./robots.txt
cd $SITE_ROOT
if [ -t 1 ]; then echo -e "\e[32mDeployment successful\e[39m"; fi
