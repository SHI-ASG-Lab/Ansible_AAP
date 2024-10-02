Automation to deploy the resources needed for Ansible Automation Platform in Azure.  

The AAP.tf file is the terraform code to deploy the following - 
 - Resource group
 - 4x RHEL 9.4 vm's
 - Network security that only allows SSH connections from a specific IP
 - Public IP on the Controller for connectivity
 - Function tags are applied to all vm's

The TF code will prompt the user for the FQDN for each device, a resource group name, an admin account name and admin password.  

The prep_#_* files are scripts that will setup all pre-reqs for the AAP installation.  

The prep scripts must be run in order 0 being first and 2 being last.

Instructions for use:
1.  Login to the Azure portal with rights to create resources and launch the cloud shell.
2.  Download the repo to the cloud shell with git or upload the files through the shell.  The only files needed in the cloud shell is the AAP.tf.  Edit the AAP.tf file with a text editor and add the Azure subscription ID, in quotes, after the equals on line 15.  Ignore the prep scripts or delete them from the cloud shell.
3.  Deploy terraform code with
    - terraform init
    - terraform apply
4.  Enter the FQDN names of each vm, name of the resource group, admin account name & admin password when prompted and yes to deploy
5.  Once the deployment is complete, close the cloud shell and navigate the newly created resource group.  Copy the public ip address and connect via SSH
6.  Download the scripts from the repo to the home directory.  Make each of the prep scripts executable with -  chmod +x prep*
7.  Run the first script with root  -  sudo ./prep_0_sudo.bash
8.  Run the second script with the local user - ./prep_1_shi.bash  *This script is interactive and the user must follow the on screen prompts.  When the RSA key is made, accepts the defaults and enter 3x.  Set the root password when prompted.  Enter the password set during the terraform install when prompted during the SSH key copy.  I recommend using the same password.
9.  Run the third script with root - sudo ./prep_2_sudo.bash  *This script is also interactive.  Follow and provide the root password set in last step during the SSH key copy.

The third script will launch the AAP setup script

