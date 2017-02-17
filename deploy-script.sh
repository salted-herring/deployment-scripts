#!/bin/bash
startTime=`date +%s`
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


END

while getopts vm:b:h option
do
    case "${option}"
    in
        v) VERBOSE=true;;
        m) CHOSEN_MODE=${OPTARG};;
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
HTACCESS="$SITE_ROOT/htaccess"
HTDOCS_DIR="htdocs"
MYSQL_HOST="localhost"
MYSQL_USER="silverstripe"
MYSQL_PASSWORD="nU3asT52uwUb"
MYSQL_DATABASE="ss_wildeyes"
REPO_DIR="repo"
ROBOTS="$SITE_ROOT/robots.txt"
SQL_DUMPS_DIR="sql-dumps"
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
cd $SITE_ROOT/$REPO_DIR
if !(git rev-parse --verify $branch &>/dev/null)
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

echo -e "\n"

# #########################################################
# 1. Git fetch
# #########################################################
GIT_SUCCESS=true
function git_fail() {
    echo -e "\e[31mRepository retrieval failed ✗\e[39m";

    if ! [ -z "$1" ]
    then
        echo -e "\e[31m$1 failed ✗\e[39m";
    fi

    echo -e "\e[31mDeployment failed ✗\e[39m";
    exit 1
}

echo -e "\e[38;5;237mGit attempting to pull from \e[1m$branch\e[22m..."
cd $SITE_ROOT/$REPO_DIR

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


# #########################################################
# 2. Composer Update
# #########################################################
COMPOSER_SUCCESS=true
if [ $MODE == "full" ]; then
    echo -e "\e[38;5;237mUpdating composer (please be patient - this may take some time)... ";
    if [ "$VERBOSE" = true ]
    then
        if ! (composer update)
        then
            COMPOSER_SUCCESS=false
            echo -e "\e[31mComposer update failed ✗\e[39m";
        fi
    else
        if ! (composer --quiet update)
        then
            COMPOSER_SUCCESS=false
            echo -e "\e[31mComposer update failed ✗\e[39m";
        fi
    fi

    if [ "$COMPOSER_SUCCESS" = true ]
    then
        echo -e "\e[32mComposer successfully updated ✓\e[39m";
    fi
fi

# #########################################################


# #########################################################
# 3. Bower Update
# #########################################################
BOWER_SUCCESS=true
if [ $MODE == "full" ]; then
    echo -e "\e[38;5;237mUpdating bower (please be patient - this may take some time)... ";
    if [ "$VERBOSE" = true ]
    then
        if ! (bower update)
        then
            BOWER_SUCCESS=false
            echo -e "\e[31mBower update failed ✗\e[39m";
        fi
    else
        if ! (bower --quiet update)
        then
            BOWER_SUCCESS=false
            echo -e "\e[31mBower update failed ✗\e[39m";
        fi
    fi

    if [ "$BOWER_SUCCESS" = true ]
    then
        echo -e "\e[32mBower successfully updated ✓\e[39m";
    fi
fi

# #########################################################


# #########################################################
# 4. MySQL Dump
# #########################################################
MYSQL_SUCCESS=true
echo -e "\e[38;5;237mStarting MySQL dump...\e[39m";
mkdir -p $SITE_ROOT/$SQL_DUMPS_DIR
cd $SITE_ROOT/$SQL_DUMPS_DIR
if [ "$VERBOSE" = true ]
then
    if !(mysqldump -v -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DATABASE-$DATABASE_VERSION.sql)
    then
        MYSQL_SUCCESS=false
    fi
else
    if !(mysqldump -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DATABASE-$DATABASE_VERSION.sql)
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

# #########################################################


# #########################################################
# 5. Archive old htdocs dir & sql dump
# #########################################################

echo -e "\e[38;5;237mArchiving the current $HTDOCS_DIR...";

HTDOCS_SUCCESS=true
cd $SITE_ROOT

if [ "$VERBOSE" = true ]
then
    if ! (tar -czvf $VERSION_NAME.tgz --exclude=assets $HTDOCS_DIR $SQL_DUMPS_DIR/$MYSQL_DATABASE-$DATABASE_VERSION.sql)
    then
        HTDOCS_SUCCESS=false
    fi
else
    if ! (tar -czf $VERSION_NAME.tgz --exclude=assets $HTDOCS_DIR $SQL_DUMPS_DIR/$MYSQL_DATABASE-$DATABASE_VERSION.sql)
    then
        HTDOCS_SUCCESS=false
    fi
fi

if [ "$HTDOCS_SUCCESS" = true ]
then
    cd $VERSIONS_DIR
    ln -sf $(basename $VERSION_NAME.tgz) latest
    echo -e "\e[32m$HTDOCS_DIR successfully archived ✓\e[39m";
else
    echo -e "\e[31m$HTDOCS_DIR archiving failed ✗\e[39m";
fi

# clean up sql
rm -rf $SITE_ROOT/$SQL_DUMPS_DIR

# #########################################################


# #########################################################
# 6. Sync repo & htdocs
# #########################################################
cd $SITE_ROOT
SYNC_SUCCESS=true
echo -e "\e[38;5;237mSynching the repo & $HTDOCS_DIR...\e[39m"

if [ "$VERBOSE" = true ]
then
    if !(rsync -av --delete $REPO_DIR/ $HTDOCS_DIR --exclude .git* --exclude .gitignore --exclude .gitmodules --exclude readme.txt --exclude .htaccess --exclude robots.txt --exclude assets)
    then
        echo -e "\e[31mSynchronisation failed ✗\e[39m";
        SYNC_SUCCESS=false
    fi
else
    if !(rsync -a --delete $REPO_DIR/ $HTDOCS_DIR --exclude .git* --exclude .gitignore --exclude .gitmodules --exclude readme.txt --exclude .htaccess --exclude robots.txt --exclude assets)
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
cd $SITE_ROOT/$HTDOCS_DIR
SAKE_SUCCESS=true
echo -e "\e[38;5;237mSynching the database...\e[39m"
if [ "$VERBOSE" = true ]
then
    if [ $MODE == "full" ]
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
    if [ $MODE == "full" ]
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

ln -sf ../assets .
cp $HTACCESS ./.htaccess
cp $ROBOTS ./robots.txt
cd $SITE_ROOT

endTime=`date +%s`
executionTime=$((endTime-startTime))

echo -e "-------------------------"
echo -e "\xF0\x9F\x8D\xBA \e[38;5;74mDeployment successful!\e[39m"
echo -e "\e[93mTime taken $executionTime seconds\e[39m"
exit 0
