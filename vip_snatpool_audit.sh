#!/bin/bash

rm /var/tmp/vip_snatpool_audit.txt

vip=$(echo y | tmsh list ltm virtual destination | grep "Display all" | awk -F" " '{ print $8 }')
echo "VIP =" $vip >> /var/tmp/vip_snatpool_audit.txt
pool=$(tmsh list ltm virtual $vip pool | grep "pool" | awk -F" " '{ print $2 }')
echo "Pool =" $pool >> /var/tmp/vip_snatpool_audit.txt
if [ "$pool" != "none" ]; then
  for member in `tmsh list ltm pool $pool members | grep "172." | awk -F" " '{ print $1 }'`; do
    status=$(tmsh show ltm pool $pool members | grep -A 3 "$member" | grep "Availability" | awk -F" " '{ print $3 }')
    echo "Pool Member =" $member "-" $status >> /var/tmp/vip_snatpool_audit.txt
  done
  snatpool=$(tmsh list ltm virtual $vip snatpool snat | grep "snat" | awk -F" " '{ print $2 }')
  echo "SNAT =" $snatpool >> /var/tmp/vip_snatpool_audit.txt
  if [ "$snatpool" != "automap" ]; then
    for snat in `tmsh list ltm snatpool $snatpool | grep "172." | awk -F" " '{ print $1 }'`; do
      echo "SNAT IP =" $snat >> /var/tmp/vip_snatpool_audit.txt
    done
  fi
fi
echo " " >> /var/tmp/vip_snatpool_audit.txt

for vip in `echo y | tmsh list ltm virtual destination | grep "virtual" | grep -v "Display all" | awk -F" " '{ print $3 }'`; do
  echo "VIP =" $vip >> /var/tmp/vip_snatpool_audit.txt
	pool=$(tmsh list ltm virtual $vip pool | grep "pool" | awk -F" " '{ print $2 }')
  echo "Pool =" $pool >> /var/tmp/vip_snatpool_audit.txt
  if [ "$pool" != "none" ]; then
    for member in `tmsh list ltm pool $pool members | grep "172." | awk -F" " '{ print $1 }'`; do
      status=$(tmsh show ltm pool $pool members | grep -A 3 "$member" | grep "Availability" | awk -F" " '{ print $3 }')
			echo "Pool Member =" $member "-" $status >> /var/tmp/vip_snatpool_audit.txt
	  done
    snatpool=$(tmsh list ltm virtual $vip snatpool snat | grep "snat" | awk -F" " '{ print $2 }')
    echo "SNAT =" $snatpool >> /var/tmp/vip_snatpool_audit.txt
    if [ "$snatpool" != "automap" ]; then
      for snat in `tmsh list ltm snatpool $snatpool | grep "172." | awk -F" " '{ print $1 }'`; do
        echo "SNAT IP =" $snat >> /var/tmp/vip_snatpool_audit.txt
	    done
    fi
  fi
  echo " " >> /var/tmp/vip_snatpool_audit.txt
done
