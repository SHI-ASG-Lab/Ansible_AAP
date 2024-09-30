# Deploying RHEL vm's to be used for Ansible Automation platform and a lane in Azure

# Terraform Azure provider and minimum version declaration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.90.0"
    }
  }
}

# Configure the Azure provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = true
    }
  }
}

# Variable Declarations
variable "env0_id" {
  type = string
}
variable "pass" {
  type = string
  default = "5ecur!ty_10I"
}
variable "region" {
  type = string
  default = "northcentralus"
}
variable "install_script" {
  type    = string
  default = "netskope_azure_client_install.ps1"
}
variable "install_script2" {
  type    = string
  default = "netskope_azure_client_install_vm2.ps1"
}
variable "aap_func" {
  type = list(string)
  default = ["AC,AH,DB,EDA"]
}
variable "ip" {
  type = list(string)
  default = ["5,6,7,8"]
}

# Create resource group
resource "azurerm_resource_group" "lane_rg" {
  name            = "Ansible_AAP"
  location        = "${var.region}"
  tags = {
    Vendor        = "RedHat"
    Product       = "AAP"
    Region        = "${var.region}"
  }
}

# Create network security group for internal subnet
resource "azurerm_network_security_group" "nsg_int" {
  name                = "internal-nsg"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name

  security_rule {
    name                       = "All_Outbound"
    priority                   = 160
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}  

# Create the virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.env0_id}-vnet"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name
  address_space       = ["10.4.0.0/16"]
}

# Create the internal subnet
resource "azurerm_subnet" "internal" {
  name                 = "Internal"
  resource_group_name  = azurerm_resource_group.lane_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.4.1.0/24"]
}

# Assign the network security group to the Internal subnet
resource "azurerm_subnet_network_security_group_association" "nsg2subnet" {
  subnet_id      = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.nsg_int.id
}

# Create the bastion host subnet
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lane_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.4.5.0/26"]
}

# Create a public IP for the bastion host
resource "azurerm_public_ip" "bastion-publicip" {
  name                = "Bastion-publicIP"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create lane Bastion host
resource "azurerm_bastion_host" "bastion" {
  name                   = "Bastion"
  location               = azurerm_resource_group.lane_rg.location
  resource_group_name    = azurerm_resource_group.lane_rg.name
  sku                    = "Standard"
  shareable_link_enabled = true
  timeouts {
    create = "60m"
    delete = "60m"
  }
  ip_configuration {
    name                 = "Bastion-ipcfg"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion-publicip.id
  }
  depends_on             =  [
    azurerm_public_ip.bastion-publicip,
    azurerm_subnet.bastion
  ]  
}

# Create nic in internal subnet
resource "azurerm_network_interface" "nic" {
  count               = length(var.aap_func)
  name                = "${count.index}-nic"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name

  ip_configuration {
    name                          = "internal_ipcfg"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.4.1.{$var.ip}"
  }
}

#Create Windows10-2 vm in internal subnet
resource "azurerm_windows_virtual_machine" "vm" {
  count               = length(var.aap_func)
  name                = "${count.index}"
  resource_group_name = azurerm_resource_group.lane_rg.name
  location            = azurerm_resource_group.lane_rg.location
  size                = "Standard_D4ds_v5"
  admin_username      = "shi"
  admin_password      = "${var.pass}"
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "94_gen2"
    version   = "latest"
  }
}
