#!/bin/bash

subnet="172.23.236."

for pool in `tmsh list ltm pool members | egrep "pool|172.23.236." | grep -B 1 "172.23.236." | grep "pool" | awk -F" " '{ print $3 }'`; do
  for member in `tmsh list ltm pool $pool members | grep ":" | awk -F " " '{ print $1 }'`; do
    if [[ $member == $subnet* ]]; then
      echo "Deleting pool member $member from pool $pool"
      tmsh modify ltm pool $pool members delete { $member }
    fi
  done
  pool_members=$(tmsh list ltm pool $pool members | grep "members" | awk -F " " '{ print $2 }')
  if [[ $pool_members == "none" ]]; then
    for vip in `echo y | tmsh list ltm virtual pool | grep -B 1 $pool | grep "virtual" | awk -F " " '{ print $3 }'`; do
      echo "Deleting VIP $vip"
      tmsh delete ltm virtual $vip
    done
    echo "Deleting pool $pool"
    tmsh delete ltm pool $pool
  fi
done
