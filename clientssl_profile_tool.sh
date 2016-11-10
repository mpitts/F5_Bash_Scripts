#!/bin/bash

# This script helps work with managing Virtual Servers' Client-SSL profiles in
# an environment where there is a many to one relationship between Virtual
# Servers and Client-SSL profiles. The primary purpose of the functions provided
# is to deal with scenarios where you will be updating a certificate or clientssl
# profile and need to identify all potentially impacted Virtual Servers.

# The following functions are available:
# 1) List all the Client-SSL profiles using a specified certificate (identified
# by providing the certificate filename as it exists on the F5).
# 2) List all Virtual Servers configured to use the specified Client-SSL profile.
# 3) Modify all Virtual Servers using a specified Client-SSL profile to use a
# different specified Client-SSL profile.

debug=1
host=$(echo $HOSTNAME | awk -F"." '{ print $1 }')

echo "What would you like to do?:"
echo "1. List all Client-SSL profiles using the specified certificate."
echo "2. List all Virtual Serverss using the specified Client-SSL profile."
echo "3. Modify all Virtual Serverss using the specified Client-SSL profile to a different specified Client-SSL profile."
echo " "
read -r -p "Type the number of the function to begin [ENTER]: " function
echo " "

if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Choose to execute function: "$function >> /var/tmp/clientssl_profile_tool_debug.log; fi;

# 1) List all the Client-SSL profiles using a specified certificate:
if [[ "$function" == "1" ]]; then
  # -- Prompt for certificate:
  read -r -p "Name of certificate (example: certificate.crt) [ENTER]: " search_certificate

  echo y | tmsh list ltm profile client-ssl cert | grep -B 1 "$search_certificate" | grep "ltm profile" | awk -F" " '{ print $4 }'

# 2) List all Virtual Servers configured to use the specified Client-SSL profile:
elif [[ "$function" == "2" ]]; then
  # -- Prompt for Client-SSL profile:
  read -r -p "Name of Client-SSL profile [ENTER]: " search_profile

  for vip in `echo y | tmsh list ltm virtual profiles | grep -B 20 "$search_profile" | grep "ltm virtual" | awk -F" " '{ print $3 }'`; do
    profile_configured=$(tmsh list ltm virtual $vip profiles | grep "$search_profile" | awk -F" " '{ print $1 }')
    if [ "$search_profile" == "$profile_configured" ]; then
  	   if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Virtual Server:" $vip "is currently using the '"$search_profile"'." >> /var/tmp/clientssl_profile_tool_debug.log; fi;
       echo $vip
    fi
  done

# 3) Modify all Virtual Servers using a specified Client-SSL profile to use a different specified Client-SSL profile.
elif [[ "$function" == "3" ]]; then
  touch /var/tmp/clientssl_profile_change_script.txt
  touch /var/tmp/clientssl_profile_backout_script.txt

  # -- Cycle through all virtual servers and look for ones using the specified clientssl profile.
  # -- Create change and backout scripts for virtual servers using the specified clientssl profile.

  if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Begin execution of Client-SSL profile changer." >> /var/tmp/clientssl_profile_tool_debug.log; fi;

  # -- Prompt for current clientssl profile.
  read -r -p "Name of current Client-SSL profile being replaced [ENTER]: " profile_change
  # -- Prompt for target clientssl profile.
  read -r -p "Name of target Client-SSL profile that is replacing the current profile [ENTER]: " profile_target

  # The script will build a change and backout script and will give the option of executing the change script if desired:
  # -- Change script is stored at "/var/tmp/clientssl_profile_change_script_HOSTNAME-DATE.txt".
  # -- Backout script is stored at "/var/tmp/clientssl_profile_backout_script_HOSTNAME-DATE.txt".
  read -r -p "Do you want to execute the change script to update the Virtual Server Client-SSL profiles (yes/no)[ENTER]? " execute
  if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Choose to execute change script: "$execute >> /var/tmp/clientssl_profile_tool_debug.log; fi;

  # Check for VIPs using the specified client-ssl profile:
  if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Begin audit of Virtual Servers using the '"$profile_change"' profile." >> /var/tmp/clientssl_profile_tool_debug.log; fi;
  for vip in `echo y | tmsh list ltm virtual profiles | grep -B 20 "$profile_change" | grep "ltm virtual" | awk -F" " '{ print $3 }'`; do
    profile_configured=$(tmsh list ltm virtual $vip profiles | grep "$profile_change" | awk -F" " '{ print $1 }')
    if [ "$profile_change" == "$profile_configured" ]; then
  	   if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Virtual Server:" $vip "is currently using the '"$profile_change"' profile, changing to '"$profile_target"'." >> /var/tmp/clientssl_profile_tool_debug.log; fi;
  	    echo "modify ltm virtual" $vip "profiles delete { "$profile_change" } profiles add { "$profile_target" { context clientside } }" >> /var/tmp/clientssl_profile_change_script.txt
  	    echo "modify ltm virtual" $vip "profiles delete { "$profile_target" } profiles add { "$profile_change" { context clientside } }" >> /var/tmp/clientssl_profile_backout_script.txt
    fi
  done

  if [ "$execute" == "yes" ]; then
  	if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Executing change script at /var/tmp/clientssl_profile_change_script.txt, the backout script can be found at /var/tmp/clientssl_profile_backout_script.txt." >> /var/tmp/clientssl_profile_tool_debug.log; fi;
  	echo "Executing change script at /var/tmp/clientssl_profile_change_script.txt, the backout script can be found at /var/tmp/clientssl_profile_backout_script.txt."
  	tmsh < /var/tmp/clientssl_profile_change_script.txt
  else
  	if [ "$debug" == 1 ]; then echo $(date +%Y-%m-%d_%H:%M:%S)" - "$host" - Change script built at /var/tmp/clientssl_profile_change_script.txt, the backout script built at /var/tmp/clientssl_profile_backout_script.txt." >> /var/tmp/clientssl_profile_tool_debug.log; fi;
  	echo "Change script built at /var/tmp/clientssl_profile_change_script.txt, the backout script built at /var/tmp/clientssl_profile_backout_script.txt."
  fi

else
  echo "Invalid input, exiting..."
  exit $?
fi
