#!/bin/bash

# AAP 2.5

# Run this script from the Controller vm as root

# 1. The function of this script is to update the /etc/hosts file with the fqdn and ip address of each of the member vm's.

# **Download to the shi user's home directory and execute as the root user or with sudo**

set -e

# IPs are set statically via the terraform deployment.  Change to fit.
IP_AC=10.250.1.5
IP_AH=10.250.1.6
IP_EDA=10.250.1.7
IP_DB=10.250.1.8
IP_GW=10.250.1.9


# Adding IP's to temp.log
echo "IP_AC=$IP_AC" >> /home/shi/temp.log
echo "IP_AH=$IP_AH" >> /home/shi/temp.log
echo "IP_EDA=$IP_EDA" >> /home/shi/temp.log
echo "IP_DB=$IP_DB" >> /home/shi/temp.log
echo "IP_GW=$IP_GW" >> /home/shi/temp.log


# Check for root permissions
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root or use sudo."
  exit 1
fi


# Get fqdn from user for each device
for i in {AC,AH,DB,EDA,GW}
  do
    #read -p "Enter IP address for $i: " ip
    read -p "Enter FQDN for $i: " fqdn
    #export IP_$i="$ip"
    export FQDN_$i="$fqdn"
    #export BOTH_$i="$ip $fqdn"
    echo "$fqdn"
    echo "$i=$fqdn" >> /home/shi/temp.log
    echo
  done


  # Get RH subscription info from user and instructions for other vm setup
read -p "Please enter your RedHat subsciption account username:  " USERNAME
echo "RHUSER=$USERNAME" >> /home/shi/temp.log
echo
read -p "Please enter your RedHat subscription password:  " PASS
echo "RHPASS=$PASS" >> /home/shi/temp.log
echo 


# Backup the original /etc/hosts file
echo "Copying original hosts file to /etc/hosts.bak"
cp /etc/hosts /etc/hosts.bak
echo


# Append the new entries to /etc/hosts
echo "Adding DB, AH & EDA entries to /etc/hosts"
echo "$IP_DB $FQDN_DB" >> /etc/hosts
echo "$IP_AH $FQDN_AH " >> /etc/hosts
echo "$IP_EDA $FQDN_EDA" >> /etc/hosts
echo "$IP_GW $FQDN_GW" >> /etc/hosts
echo 


# Change owner to shi user
chown shi:shi /home/shi/temp.log