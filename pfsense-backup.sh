#!/bin/sh


# function definition
function do_backup()
{
  wget -qO- --keep-session-cookies --save-cookies cookies.txt \
    --no-check-certificate ${url}/diag_backup.php \
    | grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/' > csrf.txt

  wget -qO- --keep-session-cookies --load-cookies cookies.txt \
    --save-cookies cookies.txt --no-check-certificate \
    --post-data "login=Login&usernamefld=${PFSENSE_USER}&passwordfld=${PFSENSE_PASS}&__csrf_magic=$(cat csrf.txt)" \
    ${url}/diag_backup.php  | grep "name='__csrf_magic'" \
    | sed 's/.*value="\(.*\)".*/\1/' > csrf2.txt

  wget --keep-session-cookies --load-cookies cookies.txt --no-check-certificate \
    --post-data "download=download${getrrd}&__csrf_magic=$(head -n 1 csrf2.txt)" \
    ${url}/diag_backup.php -q -O ${destination}/config-${PFSENSE_IP}-${timestamp}.xml
  return_value=$?
  if [ $return_value -eq 0 ]; then
    echo "Backup saved as ${destination}/config-${PFSENSE_IP}-${timestamp}.xml"
  else
    echo "Backup failed"
    exit 1
  fi

  rm cookies.txt csrf.txt csrf2.txt
}

# main execution
# check for required parameters
errors=0
if [ -z "$PFSENSE_IP" ]; then echo "Must provide PFSENSE_IP" ; errors=$(($errors + 1)) ; fi
if [ -z "$PFSENSE_USER" ]; then echo "Must provide PFSENSE_USER" ; errors=$(($errors + 1)); fi
if [ -z "$PFSENSE_PASS" ]; then echo "Must provide PFSENSE_PASS" ; errors=$(($errors + 1)); fi
if [ -z "$PFSENSE_SCHEME" ]; then echo "Must provide PFSENSE_SCHEME" ; errors=$(($errors + 1)); fi
if [ $errors -ne 0 ]; then exit 1; fi

# check for optional parameters
if [ -z "$PFSENSE_CRON_SCHEDULE" ]; then cron=0 ; else cron=1 ; fi
if [ -z "$PFSENSE_BACK_UP_RRD_DATA" ]; then
  getrrd=""
else
  if [ "$PFSENSE_BACK_UP_RRD_DATA" == "0" ] ; then
    getrrd="&donotbackuprrd=yes"
  else
    getrrd=""
  fi
fi
if [ -z "$PFSENSE_BACKUP_DESTINATION_DIR" ]; then
  destination="/data"
else
  destination="$PFSENSE_BACKUP_DESTINATION_DIR"
fi

# set up variables
url=${PFSENSE_SCHEME}://${PFSENSE_IP}
timestamp=$(date +%Y%m%d%H%M%S)

if [ $cron -eq 1 ]; then
  if [ -z "$FROM_CRON" ]; then
    echo "$PFSENSE_CRON_SCHEDULE FROM_CRON=1 /pfsense-backup.sh" | crontab -
    crond -f
  else
    do_backup
  fi
else
  do_backup
fi
