#!/bin/bash

while read -r vip; do
  found="0"
  for vs in `echo y | tmsh list ltm virtual destination | grep -B 1 "$vip" | grep "ltm virtual" | awk -F" " '{ print $3 }'`; do
    echo "VIP Found:" $vs
    found="1"
    pool=$(tmsh list ltm virtual $vs pool | grep "pool " | awk -F" " '{ print $2 }')
    echo "delete ltm virtual $vs" >> /var/tmp/vip_cleanup_change_script_$HOSTNAME.txt
    echo "delete ltm pool $pool" >> /var/tmp/vip_cleanup_change_script_$HOSTNAME.txt
  done
  if [ "$found" != 1 ]; then echo "$vip" >> /var/tmp/vip_cleanup_updated.txt; fi;
done < "vip_cleanup.txt"
