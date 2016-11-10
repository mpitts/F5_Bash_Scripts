#!/bin/bash

read -r -p "Name of old monitor to be replaced [ENTER]: " monitor_old
read -r -p "Name of new monitor [ENTER]: " monitor_new
echo " "

for pool in `tmsh list ltm pool monitor | grep -B 1 $monitor_old | grep "ltm pool" | awk -F" " '{ print $3 }'`
do 
	tmsh modify ltm pool $pool monitor $monitor_new
done
