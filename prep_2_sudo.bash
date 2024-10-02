#!/bin/bash

# Run this script from the Controller vm as root

# 1. The first function of this script is to update the /etc/hosts file with the fqdn and ip address of each of the member vm's.
# 2. Then, it registers the RHEL vm to the user's subscription.  
# 3. Then it creates the SSH keys for root and copies them to each vm.  This part is interactive and will require the user to enter the password set in the first script for the root account.
# 4. Lastly, it initiates the setup script for AAP

# **Download to the shi user's home directory and execute as the root user or with sudo**

set -e

# IPs are set statically via the terraform deployment.  Change variables to fit.
IP_AC=10.250.1.5
IP_AH=10.250.1.6
IP_EDA=10.250.1.7
IP_DB=10.250.1.8
source /home/shi/temp.log


# Check for root permissions
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root or use sudo."
  exit 1
fi


# Register and attach your Controller vm
echo "Registering the vm to RH subscription"
subscription-manager register --username "$RHUSER" --password "$RHPASS" --auto-attach
echo


# Create SSH key for root
echo "Creating SSH key"
ssh-keygen
echo


# Copy SSH keys
echo "Copying SSH keys to AH"
echo "Enter the root password of the remote vm when prompted"
echo
ssh-copy-id "$AH"
echo
echo "Copying SSH keys to DB"
echo "Enter the root password of the remote vm when prompted"
echo
ssh-copy-id "$DB"
echo
echo "Copying SSH keys to EDA"
echo "Enter the root password of the remote vm when prompted"
echo
ssh-copy-id "$EDA"
echo


# Verify directory is correct and lauch the AAP setup script
cd /home/shi/ansible-automation-platform-setup-2.4-7
echo
echo
echo
read -p "Pausing for error checking.  Press Enter to continue" NOISE
echo
echo
echo "Removing temporary install file"
# rm /home/shi/temp.log
echo
echo
echo
./setup.sh