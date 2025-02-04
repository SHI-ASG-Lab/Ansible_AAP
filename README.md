Automation to deploy the resources needed for Ansible Automation Platform in Azure.  

The aap_24 is the TF code and prep scripts to deploy AAP 2.4.  The aap_25 is the TF code and prep scripts to deploy AAP 2.5.  The instructions for use are the same for both revisions.

The ansible_env.tf file is the terraform code to deploy the following - 
 - Resource group
 - RHEL 9.4 vm's
 - Network security that only allows SSH connections from a specific IP
 - Public IP on the Controller for connectivity
 - Function tags are applied to all vm's
 - A jumpbox for local access 

The TF code will prompt the user for the FQDN for each device, the azure subscription id, a resource group name, the public ip of the user, and the admin password.  

The prep_#_* files are BASH scripts that will setup all pre-reqs for the AAP installation.  

The prep scripts must be run in order 1 being first and 3 being last.

Instructions for use:
1.  Login to the Azure portal with rights to create resources and launch the BASH cloud shell.
2.  Download the repo to the cloud shell with git or upload the ansible_env.tf file through the shell.  The only files needed in the cloud shell is the ansible_env.tf.  Ignore the prep scripts or delete them from the cloud shell.  You can create a terraform.tfvars file with the variables and values for faster deployment.  Variables are written - variable_name = "value"
3.  Deploy terraform code with
    - terraform init
    - terraform apply
4.  Enter the FQDN names of each vm, name of the resource group & admin password when prompted and yes to deploy.  The admin_public_ip prompt is asking for the public ip of the user who will be accessing.  If it's you using this, then figure out your public ip and use that.  You will use this password throughout the steps below.  I highly recommend you use the same password throughout this process for ease sake, but you don't have too.
5.  Once the deployment is complete, close the cloud shell and navigate the newly created resource group.  Select the controller vm (name will be the ac_fqdn from the tf deployment), copy the public ip address and connect via SSH using a terminal or command shell.  The user created is called "shi" - ssh shi@<public_ip_of_controller_vm>.  Use the password supplied during the tf deployment (pass value).
6.  Download the scripts from the repo to the home directory and change to that directory.  You will need to install "git" first, so run - sudo dnf -y install git - Then run - git clone https://github.com/SHI-ASG-Lab/Ansible_AAP.git  - Make each of the prep scripts executable with -  chmod +x prep* 
7.  Run the first script with root  -  sudo ./prep_1_sudo.bash  -  Enter the same FQDN's provided during the TF deployment.  Each of the hosts have the hostname set to the name of the vm in azure.  
8.  Run the second script with the shi user - ./prep_2_shi.bash
    - This script is interactive and the user must follow the prompts.  When the RSA key is made, accept the defaults and hit enter 3x.  Set the root password when prompted.  This will be the password you will use to login to the web consoles of the AAP components (step 12).  Enter the password set during the terraform install when prompted during the SSH key copy.  I recommend using the same password.
9.  Run the third script with root - sudo ./prep_3_sudo.bash
    - This script is also interactive.  Follow and provide the root password set in last step during the SSH key copy.
    - This script will pause for error checking before launching the AAP setup script.  Hit any key to continue.
10.  Connect to the Jumpbox vm through the Azure portal.  Deploy and use the bastion and connect with the shi account and the password set during the TF deployment.  Edit the c:\Windows\System32\drivers\etc\hosts with the IP's and FQDN's of the AAP components.
    - 10.250.1.5 <ac_fqdn> # Controller FQDN
    - 10.250.1.6 <ah.fqdn> # Automation Hub FQDN
    - 10.250.1.7 <eda_fqdn> # Event Driven Automation FQDN
11.  From the Jumpbox, open a browser and navigate to the Controller's domain name - https://<ac_fqdn>   Do the same for Automation Hub & Event Driven Automation controller - https://<ah_fqdn> - https://<eda_fqdn>.  Login with "Admin" and the password set during the scripted install in step 8 for all 3 GUI's.  

**This script downloads the AAP installer zip from a static storage account, so there ia a possibility it's out of date.  It's very possible newer versions will not work with this TF template though.  It's easy to modify the TF code to suite your needs.

