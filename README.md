# SIlverStripe Deployment script
This script deploys SilverStripe based sites. It performs the following actions:

1. Backs up current database & files
2. Checks out the latest code
3. Optionally updates composer & bower
4. Synchronises the current site with the newly checked out code
5. Synchronises the databases

-----

## USAGE:

`./deployscript.sh [options]`

  -v Verbose - log all output

  -m Mode    - indicates whether we run bower & composer - 1 for "Lite" 
mode; 2 for "Full" mode

  -b Branch  - the branch to deploy from

  -h Help    - Display this help

---

## REQUIREMENTS:
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
