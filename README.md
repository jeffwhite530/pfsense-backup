## Short description
Runs a lightweight Alpine container to back up PFSense.

## Full details
This image can be used to run a one-time backup of PFSense, or it can be configured to stay in the background and retrieve backups on a user-specified schedule.

Tested with PFSense 2.4.5-RELEASE-p1. By default the backup will contain all the RRD data. If that is not desired see Parameters section below.

### Running
#### One-time container
This is a good method for testing to ensure all the parameters are correct. If this command does not succeed, the cron-version below will not succeed either.

Running this command will start the container, connect to the PFSense host specified with the credentials provided, and retrieve a backup. The backup file will be placed in the directory the command was run from, the container will then quit.
```
docker run --rm --volume $(pwd):/data --env PFSENSE_USER=backupuser --env PFSENSE_IP=192.168.0.1 --env PFSENSE_PASS=changeme --env PFSENSE_SCHEME=https pfsense-backup
```
#### Continuous container
Test your configuration with the one-time version above before trying the continuous backup mode out.

Running this command will start the container and send it to the background. While in the background the container will connect to the PFSense host specified with the credentials provided and retrieve a backup. The backup file will be placed in the directory the command was run from. On the cron schedule, a new backup file will be placed in that directory.

This specific command will back up once per day at midnight UTC, as the container's default time zone is set to UTC.
```
docker run --detach --volume $(pwd):/data --env PFSENSE_USER=backupuser --env PFSENSE_IP=192.168.0.1 --env PFSENSE_PASS=changeme --env PFSENSE_SCHEME=https --env PFSENSE_CRON_SCHEDULE='0 0 * * *' zxjinn/pfsense-backup
```

### Parameters
- `PFSENSE_USER` Required. The PFSense user to log in with.
- `PFSENSE_PASS` Required. The password for the PFSense user specified.
- `PFSENSE_USER` Required. The IP (or DNS name) of the PFSense server.
- `PFSENSE_SCHEME` Required. Should either be `http` or `https`. This parameter is not validated.
- `PFSENSE_CRON_SCHEDULE` Optional. The cron schedule to use, should contain 5 items separated by spaces. This parameter is not validated. No default.
- `PFSENSE_BACK_UP_RRD_DATA`. Optional. Should be either 1 or 0. This parameters is not validated. Include RRD data in the backup? 1=yes, 0=no. Default=1
- `PFSENSE_BACKUP_DESTINATION_DIR`. Optional. What is the destination directory to back up to. This directory must exist and be writable. Default=/data
- `TZ` Optional. What time zone the container should use. Default=UTC
- `RM_BACKUPS_MAX_AGE_DAYS` Optional. Remove backups older than this many days.

## Help!
- Is the username correct?
- Is the password correct? Is it quoted properly?
- The container runs in the UTC timezone, so the cron schedule might be offset from what was expected.

## Credits
Hat tip to [furiousgeorge/pfsense-backup](https://hub.docker.com/r/furiousgeorge/pfsense-backup/) for the idea and some of the code, github at [hannah98/pfsense-backup](https://github.com/hannah98/pfsense-backup). This version was forked from [zxjinn/pfsense-backup](https://github.com/zxjinn/pfsense-backup).
