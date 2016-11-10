#!/bin/bash

read -r -p "Enter the cipher you are looking for (example: RC4-SHA) [ENTER]: " cipher
echo " "

for profile in `tmsh list ltm profile client-ssl ciphers | grep -B 1 $cipher | grep "profile" | awk -F" " '{ print $4 }'`
do
	for vip in `echo y | tmsh list ltm virtual profiles | grep -B 10 $profile | grep "virtual" | awk -F" " '{ print $3 }'`
	do
		state=$(tmsh show ltm virtual $vip | grep "Availability" | awk -F" " '{ print $3 }')
		echo "Virtual Server:" $vip "-- Client-SSL Profile:" $profile "-- Availability:" $state
	done
done
