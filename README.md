# SilverStripe Deployment script
This script deploys SilverStripe based sites. It performs the following actions:

1. Backs up current database & files
2. Checks out the latest code
3. Optionally updates composer & bower
4. Synchronises the current site with the newly checked out code
5. Synchronises the databases

---
## USAGE

`./deployscript.sh [options]`

 -S Site Root       - Path to the root (parent of the public directory) of the site.
 -v Verbose         - log all output
 -m Mode            - indicates whether we run bower & composer - 1 for "Lite" mode; 2 for "Full" mode
 -b Branch          - the branch to deploy from
 -e Environment     - The SilverStripe environment (e.g. "dev" or "live")
 -h Help            - Display this help
 -i Non-interactive - Allow script to execute without waiting at each step.
 -t Theme           - Theme to use when running bower
 -c Config          - json file with default settings

Using a config file overrides all settings.
Asking for the help prints out the description & usage & exits.

---

## REQUIREMENTS
This is intended to run on a Linux environment. This has been tested with:

1. Ubuntu 14.04

The following packages will need to be installed:

1. realpath
2. basename
3. git
4. composer
5. bower
6. mysqldump
7. tar
8. rsync
9. php 5.6+
10. MySQL
11. Apache (nginx is not supported currently)
12. jq (https://stedolan.github.io/jq/)

---

## CONFIGURATION

The options that are passed into the CLI, may also be provided by an optional ison file. For example:

```json
{
    "apache_version": 2.4,
    "environment": "dev",
    "interactive": "true",
    "root": "/var/www/silverstripe.domain",
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
        "branch": "master",
        "theme": "default"
    },
    "services": {
        "bower": true,
        "composer": true
    }
}
```

*apache_version* - a simple string indicating the major release (i.e. 2.4 not 2.4.7)  
*root* - root directory of the site (parent level of public directory - e.g. /var/www/hostname - not /var/www/hostname/htdocs). Ensure there is no trailing slash

## INSTALLATION

### UBUNTU
The recommended way to install this is the following:

```sh
cd /user/lcoal/bin
git clone git@github.com:salted-herring/deployment-scripts.git ss-deployment
ln -s ss-deployment/deployment-script.sh ssdeploy
```

You should then be able to run this whereever you want - e.g. `ssdeploy -c ./jsonpath`
