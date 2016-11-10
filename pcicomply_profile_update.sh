#!/bin/bash

cipher=":RC4-SHA"

echo "Do you want the script to execute the changes to update the profiles (yes/no)[ENTER]?"
read execute

for x in `tmsh list ltm profile client-ssl ciphers | grep -B 1 $cipher | grep "profile" | awk -F" " '{ print $4 }'`; do
	if [ $x != "clientssl-pcicomply" ]; then
		parent=$(tmsh list ltm profile client-ssl $x defaults-from | grep "defaults-from" | awk -F" " '{ print $2 }')
		if [ "$parent" != "clientssl-pcicomply" ]; then
			cert=$(tmsh list ltm profile client-ssl $parent cert | grep "cert" | awk -F" " '{ print $2 }')
			key=$(tmsh list ltm profile client-ssl $parent key | grep "key" | awk -F" " '{ print $2 }')
			chain=$(tmsh list ltm profile client-ssl $parent chain | grep "chain" | awk -F" " '{ print $2 }')
			echo "modfiy ltm profile client-ssl $x defaults-from clientssl-allstate_tactical_pcicomply cert $cert key $key chain $chain" >> /var/tmp/pcicomply_profile_change_script.txt
			echo "Client SSL profile" $x "may need to have the 'ciphers' setting unchecked after executing the change."
			echo "# Client SSL profile" $x "may need to have the 'ciphers' setting unchecked." >> /var/tmp/pcicomply_profile_change_script.txt
			echo "modfiy ltm profile client-ssl $x defaults-from clientssl-allstate_standard_insecure" >> /var/tmp/pcicomply_profile_backout_script.txt
		else
			echo "modfiy ltm profile client-ssl $x defaults-from clientssl-allstate_tactical_pcicomply" >> /var/tmp/pcicomply_profile_change_script.txt
			echo "modfiy ltm profile client-ssl $x defaults-from clientssl-allstate_standard_insecure" >> /var/tmp/pcicomply_profile_backout_script.txt
		fi
		echo "===== Profile" $x "is used by the following VIPs =====" >> /var/tmp/pcicomply_profile_vips.txt
		for y in `echo y | tmsh list ltm virtual profiles | grep -B 10 $x | grep "virtual" | awk -F" " '{ print $3 }'`; do
			state=$(tmsh show ltm virtual $y | grep "Availability" | awk -F" " '{ print $3 }')
			echo "    " $y "    " $state >> /var/tmp/pcicomply_profile_vips.txt
		done
	fi
done

if [ "$execute" == "yes" ]; then
	echo "Executing change script at /var/tmp/pcicomply_profile_change_script.txt, the backout script can be found at /var/tmp/pcicomply_profile_backout_script.txt"
	tmsh < /var/tmp/pcicomply_profile_change_script.txt
else
	echo "Change script built at /var/tmp/pcicomply_profile_change_script.txt, the backout script built at /var/tmp/pcicomply_profile_backout_script.txt"
fi


