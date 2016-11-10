#!/bin/bash

cipher=":RC4-SHA"

for x in `tmsh list ltm profile client-ssl ciphers | grep -B 1 $cipher | grep "profile" | awk -F" " '{ print $4 }'`
do
	for y in `echo y | tmsh list ltm virtual profiles | grep -B 10 $x | grep "virtual" | awk -F" " '{ print $3 }'`
	do
		state=$(tmsh show ltm virtual $y | grep "Availability" | awk -F" " '{ print $3 }')
		echo $y "     " $state
	done
done
