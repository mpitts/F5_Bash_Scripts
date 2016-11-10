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
				p_result=fail	# Prime the p_result variable.
				# Check for reachability to each pool member:
				for i in `tmsh list ltm pool $pool | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk -F" " '{ print $1 }' | awk -F":" '{ print $1 }'`; do
					ping -q -W 1 -c 1 $i
					if [ $(echo $?) -eq 0 ]; then p_result=success; fi;	# Ping the pool member and change the p_result variable if ANY pool member is reachable.
				done
				# Only disable the VIP is all pool members were unreachable:
				if [ $p_result != success ]; then
					echo "No events found for" $x", adding to disable script and IP reclaim list."
					# Adds the VIP to a TMSH script file that can be executed to disable the VIPs:
					echo "modify ltm virtual" $x "disabled" >> /var/tmp/offline_vips-disable_script.txt
					# Adds the VIP IP and port to a list that can be used to clean up IPAM and FW rules:
					echo $(tmsh list ltm virtual $x | grep destination | awk -F" " '{ print $2 }') >> /var/tmp/offline_vips-ip_reclaim.txt
				fi
			fi
		fi
	fi
done

# If the script was instructed to execute the change script:
if [ "$execute" == "yes" ]; then
	echo "Executing change script at /var/tmp/offline_vips-disable_script.txt."
	tmsh < /var/tmp/offline_vips-disable_script.txt
	echo "IP reclaim list built at /var/tmp/offline_vips-ip_reclaim.txt."
else
	echo "Change script built at /var/tmp/offline_vips-disable_script.txt."
	echo "IP reclaim list built at /var/tmp/offline_vips-ip_reclaim.txt."
fi
