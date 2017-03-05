# Configuration Options
The tool comes with a number of configuration options to setup the deployment. In order to run the tool a config.json file **must** be supplied.

Here is an example:

```json
{
    "apache_version": 2.4,
    "environment": "dev",
    "interactive": "true",
    "verbose": false,
    "mysql": {
        "host": "localhost",
        "database_name": "ss_deployment",
        "username": "silverstripe",
        "password": "password"
    },
    "paths": {
        "root": "/var/www/silverstripe.domain/",
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
    "archiving": {
        "scheme": "files",
        "limit": "4"
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
```

**Note:** all config options are required.

## Option Values

**apache_version**  
e.g. 2.x *(only 1 minor version - i.e. 2.4.7 is not accepted)*

The tool has been tested with apache 2.4. It may work with nginx and older versions, we haven’t officially tested it yet.

**environment**  
*“dev”* or *“live”*

The SilverStripe environment to run under.

**interactive**  
*boolean*

Whether to force the user to advance the tool manually after each step.

**verbose**  
*boolean*

Enable/disable verbose logging.

**mysql**  
Database connection details:

| **host** | host name |
|  **database_name** | database name |
| **username** | database user name |
| **password** | database password |

**paths**  
Required path variables:

| **root** | Base path to the installation. If we’re running apache the path would be `/var/www/hostname`, not `/var/www/hostname/public` |
|  **htdocs** | Name of the public files directory within *root* |
| **versions** | Name of the archived files directory within *root* |
| **repo** | Name of the repository directory within *root* |
| **sql_dumps** | Name of the sql dumps directory within *root* — note: this is a temporary directory |
| **themes** | Name of the themes directory (within *htdocs*) |

**default**  
Some generic setup options:

|  **mode** | 1 or 2 |
|  **theme** | The name of the theme we are using |

*Notes on mode:*  
The mode has 2 options:

* **1 (Lite):** Simply update any code changes
* **2 (Full):** Includes running composer & bower as well

**logging**  
Options for logging:

|  **enabled** | boolean |
|  **directory** | Absolute path to log directory |
|  **filename** | Name of log file within directory |

**archiving**  
Options for archiving:

|  **scheme** | `“size”` or `“files”` |
|  **limit** | `int` |

Archiving allows for 2 modes:

* Size limit
* Number of backups limit

When in **size** mode, **limit** refers to the total max size in MB all archives can be. When in **files** mode,  **limit** refers to the maximum number of backups to keep.

When a limit is reached, the system will replace the oldest backup with a new backup.

**services**  
*`name => boolean`*

Any services beyond repository syncing, database backup & archiving are listed here. At the moment there is only **bower** & **composer**.

**repository**  
Details target for deployment. It is assumed that the **repo** path (as found in paths -> repo) has been initialised to an active git repository & the user has at least fetch & pull access.

|  **mode** | `“branch”` or `“tag”` |
|  **target** | `branch or tag name` |

The target relates specifically to the mode - e.g. if specifying tag mode, then the target must be a tag.
