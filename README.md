Automation to deploy the resources needed for Ansible Automation Platform in Azure.  

The AAP.tf file is the terraform code to deploy the following - 
 - Resource group
 - 4x RHEL 9.4 vm's
 - Network security that only allows SSH connections from a specific IP
 - Public IP on the Controller for connectivity
 - Function tags are applied to all vm's

The TF code will prompt the user for the FQDN for each device, a resource group name, the public ip of the user, and the admin password.  

The prep_#_* files are scripts that will setup all pre-reqs for the AAP installation.  

The prep scripts must be run in order 0 being first and 2 being last.

Instructions for use:
1.  Login to the Azure portal with rights to create resources and launch the cloud shell.
2.  Download the repo to the cloud shell with git or upload the AAP.tf file through the shell.  The only files needed in the cloud shell is the AAP.tf.  Edit the AAP.tf file with a text editor and add the Azure subscription ID, in quotes, after the equals on line 15.  Ignore the prep scripts or delete them from the cloud shell.
3.  Deploy terraform code with
    - terraform init
    - terraform apply
4.  Enter the FQDN names of each vm, name of the resource group & admin password when prompted and yes to deploy.  The admin_public_ip prompt is asking for the public ip of the user who will be accessing.  If it's you using this, then figure out your public ip and use that.  
5.  Once the deployment is complete, close the cloud shell and navigate the newly created resource group.  Select the controller vm (name will be the ac_fqdn from the tf deployment), copy the public ip address and connect via SSH using a terminal or command shell.  The user created is called "shi" - ssh shi@<public_ip_of_controller_vm>.  Use the password supplied during the tf deployment (pass value).
6.  Download the scripts from the repo to the home directory and change to that directory.  Make each of the prep scripts executable with -  chmod +x prep* 
7.  Run the first script with root  -  sudo ./prep_0_sudo.bash
8.  Run the second script with the shi user - ./prep_1_shi.bash
   - This script is interactive and the user must follow the prompts.  When the RSA key is made, accept the defaults and hit enter 3x.  Set the root password when prompted.  Enter the password set during the terraform install when prompted during the SSH key copy.  I recommend using the same password.
10.  Run the third script with root - sudo ./prep_2_sudo.bash
   - This script is also interactive.  Follow and provide the root password set in last step during the SSH key copy.

The third script will launch the AAP setup script

This script downloads the AAP installer zip from a static storage account, so there ia a possibility it's out of date.  To change to a different AAP zip, edit prep_1_shi.bash, line 81 with the updated link and file name and update line 83 with new filename to unzip.  Then do a global replace for the old ansible zip for the new one to update the inventory file pieces.

