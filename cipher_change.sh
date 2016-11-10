#!/bin/bash

cipher=":RC4-SHA"

for x in `tmsh list ltm profile client-ssl ciphers | grep -B 1 $cipher | grep "profile" | awk -F" " '{ print $4 }'`
do 
	tmsh list ltm profile client-ssl defaults-from | grep -A 1 $x
done
