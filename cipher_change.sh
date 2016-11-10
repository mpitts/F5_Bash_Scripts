#!/bin/bash

read -r -p "Enter the cipher you are looking for (example: RC4-SHA) [ENTER]: " cipher
echo " "

for profile in `tmsh list ltm profile client-ssl ciphers | grep -B 1 $cipher | grep "profile" | awk -F" " '{ print $4 }'`
do
	tmsh list ltm profile client-ssl defaults-from | grep -A 1 $profile
done
