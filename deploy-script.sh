# ###########################################
# deploy-script.sh
# ----------------
# deployment script for salted herring sites.
# Performs the following tasks:
# 1. Backup current db.
# 2. Checks out latest code.
# 3. Backs up current site.
# 4. Synchs with composer & bower
# 5. Updates db with current state.
# ###########################################

#
# Script vars. Set these up prior to running.
#
SITE_ROOT="/home/saltydev/domains/dev-9spokes.saltydev.com"
DEFAULT_BRANCH="develop"
HTDOCS_DIR="public_html"
SQL_DUMPS_DIR="sql-dumps"
REPO_DIR="bbrepo"
VERSIONS_DIR="versions"
MSQL_HOST="localhost"
MSQL_USER="saltydev"
MYSQL_PASSWORD="JtfbVzt9BPX2iHnN"
MSQL_DATABASE="dev_9spokes"
VERSION_NAME=$SITE_ROOT/$VERSIONS_DIR/$(date "+%Y-%m-%d-%H_%M_%S")
HTACCESS="$SITE_ROOT/htaccess"
ROBOTS="$SITE_ROOT/robots.txt"
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

mkdir -p $SITE_ROOT/$SQL_DUMPS_DIR
mysqldump -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $SQL_DUMPS_DIR/$MYSQL_DATABASE-$(date "+%b_%d_%Y_%H_%M_%S").sql

if [ -t 1 ]; then echo -e "\e[32mMySQL dump successful\e[39m"; fi
cd $SITE_ROOT/$REPO_DIR
git fetch --all
git checkout $branch
git checkout composer.lock
git pull origin $branch
if [ -t 1 ]; then echo -e "\e[32mPulled from $branch branch\e[39m"; fi

if [ $MODE == "full" ];
then
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
if [ -t 1 ]; then echo -e "\e[32mCurrent public_html has been depreciated\e[39m"; fi
rm -rf $SITE_ROOT/$HTDOCS_DIR;
ln -s $VERSION_NAME $SITE_ROOT/$HTDOCS_DIR
cd $SITE_ROOT/$HTDOCS_DIR
if [ -t 1 ]; then echo -e "\e[32mCreating symbolic link to assets directory...\e[39m"; fi
rm -rf $SITE_ROOT/$HTDOCS_DIR/assets
ln -s $SITE_ROOT/assets .
if [ -t 1 ]; then echo -e "\e[32mRefreshing database\e[39m"; fi


cd $SITE_ROOT/$HTDOCS_DIR

if [ $MODE == "full" ];
then
    sake dev/build flush=all;
else
    sake dev/build;
fi
if [ -t 1 ]; then echo -e "\e[32mDatabase refreshed\e[39m"; fi
if [ -t 1 ]; then echo -e "\e[32mCleaning...\e[39m"; fi
rm -rf composer.*
rm -rf .git*
rm .editorconfig
cp $HTACCESS ./.htaccess
cp $ROBOTS ./robots.txt
cd $SITE_ROOT
if [ -t 1 ]; then echo -e "\e[32mDeployment successful\e[39m"; fi
