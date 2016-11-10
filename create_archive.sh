#!/bin/bash

archive_server="10.14.22.29"
archive_user="f5archive"
archive_password="$@mcr0"
archive_directory="/f5_archives"

host=$(echo $HOSTNAME | awk -F"." '{ print $1 }')
archive_date=$(date +%Y-%m-%d)

# Create UCS backup of device:
tmsh save sys ucs /var/tmp/$archive_date-$host.ucs

# Transfer UCS to remote server:
echo $archive_password | scp /var/tmp/$archive_date-$host.ucs $archive_user@$archive_server:$archive_directory/$archive_date-$host.ucs

# Clean-up UCS:
rm /var/tmp/$archive_date-$host.ucs
