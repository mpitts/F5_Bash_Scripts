#!/bin/bash

# This script will identify VIPs that have been in an offline state for the duration of the logs that kept on the appliance.

# Prompt the user to determine if script is to execute the removal script or just build it:
read -r -p "Do you want the script to execute the change script to disable the VIPs (yes/no)[ENTER]? " execute

for x in `echo y | tmsh show ltm virtual | grep -B 3 "offline" | grep "Ltm::Virtual Server" | awk -F" " '{ print $3 }'`
do
	# Skip if the VIP is already disabled:
	if [ $(echo y | tmsh show ltm virtual $x | grep "State" | awk -F" " '{ print $3 }') != "disabled" ]; then
		pool=$(tmsh list ltm virtual $x | grep " pool " | awk -F" " '{ print $2 }')
		# Checks to see if there are any events in the current LTM log:
		if [ $(cat /var/log/ltm | grep $pool) ]; then
			echo "Events were found for " $x
		else
			# Checks to see if there are any events in the archive LTM logs:
			if [ $(zcat /var/log/ltm.*.gz | grep $pool) ]; then
				echo "Events were found for " $x
			else
				echo "No events found for" $x", adding to disable script and IP reclaim list."
				# Adds the VIP to a TMSH script file that can be executed to disable the VIPs:
				echo "modify ltm virtual" $x "disabled" >> /var/tmp/offline_vips-disable_script-likely.txt
				# Adds the VIP IP and port to a list that can be used to clean up IPAM and FW rules:
				echo $(tmsh list ltm virtual $x | grep destination | awk -F" " '{ print $2 }') >> /var/tmp/offline_vips-ip_reclaim-likely.txt
			fi
		fi
	fi
done

# If the script was instructed to execute the change script:
if [ "$execute" == "yes" ]; then
	echo "Executing change script at /var/tmp/offline_vips-disable_script-likely.txt."
	tmsh < /var/tmp/offline_vips-disable_script-likely.txt
	echo "IP reclaim list built at /var/tmp/offline_vips-ip_reclaim-likely.txt."
else
	echo "Change script built at /var/tmp/offline_vips-disable_script-likely.txt."
	echo "IP reclaim list built at /var/tmp/offline_vips-ip_reclaim-likely.txt."
fi
