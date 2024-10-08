#!/bin/bash

# AAP 2.5

# Run this script from the Controller vm first as the shi user

# 1. The first function of this script is to create the SSH keys for the shi user and copy them to the members vm's.  This is interactive and will require the user to enter the password set during the terraform deployment.
# 2. Second is to install ansible-core and the download the playbooks.
# 3. Then it creates the ansible variables & inventory file, then executes the playbooks to set the root password and execute the subscription registration on each remote vm.  Required for the AAP installation.
# 4. Finally, it downloads the AAP zip file, unzips it and creates the inventory file will all settings in place for deployment.

# **Download to the shi user's home directory and execute as the shi user, not sudo**

set -e

# IPs are set statically via the terraform deployment.  Change variables to fit but be sure to match in the other prep script.
IP_AC=10.250.1.5
IP_AH=10.250.1.6
IP_EDA=10.250.1.7
IP_DB=10.250.1.8
IP_GW=10.250.1.9
source /home/shi/temp.log


# Get the ansible zip name and write it to log file
read -p "Enter the AAP zip name to be used:  " AAP_ZIP
echo "AAP_ZIP="$AAP_ZIP"" >> /home/shi/temp.log
echo

# Get directory name and write it to log file
DIR_NAME="${AAP_ZIP%.tar.gz}"
echo "DIR_NAME="$DIR_NAME"" >> /home/shi/temp.log

# Get the password to use for root from user
read -p "Enter the password to set for root accounts and the AAP logins.  It is recommended that you use the same password as the terraform system password.  Enter password:  " PASS


# Create SSH key for shi user
echo "Creating SSH key for shi user"
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
echo


# Copy SSH keys for shi user
echo "Copying SSH keys to AH for shi user"
echo "Enter the same password from the terraform deployment "
echo
ssh-copy-id "$AH"
echo
echo "Copying SSH keys to DB for shi user"
echo "Enter the same password from the terraform deployment "
echo
ssh-copy-id "$DB"
echo
echo "Copying SSH keys to EDA for shi user"
echo "Enter the same password from the terraform deployment "
echo
ssh-copy-id "$EDA"
echo
echo "Copying SSH keys to GW for shi user"
echo "Enter the same password from the terraform deployment "
echo
ssh-copy-id "$GW"
echo


# Installing ansible-core, downloading/moving the ansbile playbooks and vars file
sudo dnf -y install ansible-core
mkdir /home/shi/ansibleprep
cd /home/shi/ansibleprep
mv /home/shi/Ansible_AAP/change_root_pwd.yml /home/shi/ansibleprep/change_root_pwd.yml
mv /home/shi/Ansible_AAP/shell_command.yml /home/shi/ansibleprep/shell_command.yml
mv /home/shi/Ansible_AAP/dnf_update_all.yml /home/shi/ansibleprep/dnf_update_all.yml

# Creating the ansible variables file, adding the user's password & create the inventory file with the remote vm's info 
echo "userpwd: $PASS" >> /home/shi/ansibleprep/Change_root_pwd_vars.yml
echo "registration: ""subscription-manager register --username "$RHUSER" --password "$RHPASS" --auto-attach""" >> /home/shi/ansibleprep/Change_root_pwd_vars.yml
echo "$AH" >> /home/shi/ansibleprep/inventory.yml
echo "$EDA" >> /home/shi/ansibleprep/inventory.yml
echo "$DB" >> /home/shi/ansibleprep/inventory.yml
echo "$GW" >> /home/shi/ansibleprep/inventory.yml


# Execute playbook to set the root password and register the other vm's
ansible-playbook -i /home/shi/ansibleprep/inventory.yml /home/shi/ansibleprep/change_root_pwd.yml
ansible-playbook -i /home/shi/ansibleprep/inventory.yml /home/shi/ansibleprep/shell_command.yml
ansible-playbook -i /home/shi/ansibleprep/inventory.yml /home/shi/ansibleprep/dnf_update_all.yml


# Deleting vars file with the password
rm /home/shi/ansibleprep/Change_root_pwd_vars.yml


# Change to the user directory
cd /home/shi


# Curl the ansible setup script from static storage account  **Need to make this a download from the RH repo latest**
echo "Downloading the ansible setup zip"
curl -o /home/shi/$AAP_ZIP https://lodscripts.blob.core.windows.net/lod-sse-scripts/$AAP_ZIP
echo
tar -xzf /home/shi/$AAP_ZIP
echo


# Change to unzipped ansible directory
cd /home/shi/$DIR_NAME
echo


# Backup the inventory file for reference later
echo "Copying the original inventory file to inventory.org"
mv inventory inventory.org
echo


# Create new inventory file
echo "Creating inventory file"
echo "# Ansible Automation Platform 2.5 inventory file" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# Gateway
echo "# AAP Gateway hosts" >> /home/shi/$DIR_NAME/inventory
echo "[automationgateway]" >> /home/shi/$DIR_NAME/inventory
echo "$GW" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# Controller
echo '[automationcontroller]' >> /home/shi/$DIR_NAME/inventory
echo "$AC ansible_connection=local" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

echo "[automationcontroller:vars]" >> /home/shi/$DIR_NAME/inventory
echo "peers=execution_nodes" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# Execution nodes 
echo "[execution_nodes]" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# Automation hub
echo "[automationhub]" >> /home/shi/$DIR_NAME/inventory
echo "$AH" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# EDA 
echo "[automationedacontroller]" >> /home/shi/$DIR_NAME/inventory
echo "$EDA" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# DB
echo "[database]" >> /home/shi/$DIR_NAME/inventory
echo "$DB" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

#echo "# Controller Configuration" >> /home/shi/$DIR_NAME/inventory
echo "[all:vars]" >> /home/shi/$DIR_NAME/inventory
#echo "registry_url='registry.redhat.io'" >> /home/shi/$DIR_NAME/inventory
echo "registry_username='$RHUSER'" >> /home/shi/$DIR_NAME/inventory
echo "registry_password='$RHPASS'" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# Gateway config
echo "# Gateway configuration" >> /home/shi/$DIR_NAME/inventory
echo "automationgateway_admin_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
echo "automationgateway_pg_host=$DB" >> /home/shi/$DIR_NAME/inventory
echo "automationgateway_pg_database='automationgateway'" >> /home/shi/$DIR_NAME/inventory
echo "automationgateway_pg_username='automationgateway'" >> /home/shi/$DIR_NAME/inventory
echo "automationgateway_pg_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# Controller config
echo "# Controller configuration" >> /home/shi/$DIR_NAME/inventory
echo "admin_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
echo "pg_host=$DB" >> /home/shi/$DIR_NAME/inventory
#echo "pg_port=5432" >> /home/shi/$DIR_NAME/inventory
echo "pg_database='awx'" >> /home/shi/$DIR_NAME/inventory
echo "pg_username='awx'" >> /home/shi/$DIR_NAME/inventory
echo "pg_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
#echo "pg_sslmode='prefer'" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

#echo "" >> /home/shi/$DIR_NAME/inventory
#echo "receptor_listener_port=27199" >> /home/shi/$DIR_NAME/inventory
#echo "" >> /home/shi/$DIR_NAME/inventory

# Automation hub config
echo "# Automation Hub Configuration" >> /home/shi/$DIR_NAME/inventory
echo "automationhub_admin_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
echo "automationhub_pg_host=$DB" >> /home/shi/$DIR_NAME/inventory
#echo "automationhub_pg_port=5432" >> /home/shi/$DIR_NAME/inventory
echo "automationhub_pg_database='automationhub'" >> /home/shi/$DIR_NAME/inventory
echo "automationhub_pg_username='automationhub'" >> /home/shi/$DIR_NAME/inventory
echo "automationhub_pg_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
#echo "automationhub_pg_sslmode='prefer'" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# EDA config 
echo "# Event Driven Automation Configuration" >> /home/shi/$DIR_NAME/inventory
echo "automationedacontroller_admin_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
echo "automationedacontroller_pg_host=$DB" >> /home/shi/$DIR_NAME/inventory
#echo "automationedacontroller_pg_port=5432" >> /home/shi/$DIR_NAME/inventory
echo "automationedacontroller_pg_database='automationedacontroller'" >> /home/shi/$DIR_NAME/inventory
echo "automationedacontroller_pg_username='automationedacontroller'" >> /home/shi/$DIR_NAME/inventory
echo "automationedacontroller_pg_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
echo "" >> /home/shi/$DIR_NAME/inventory

# Uncomment the lines below if using AAP 2.4
# SSO configuration
#echo "# SSO Configuration" >> /home/shi/$DIR_NAME/inventory
#echo "sso_keystore_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
#echo "sso_console_admin_password='$PASS'" >> /home/shi/$DIR_NAME/inventory
#echo "" >> /home/shi/$DIR_NAME/inventory
echo