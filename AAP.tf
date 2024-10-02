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
  subscription_id = "e6cc4314-b5cb-41d8-bcd9-02f438f59b84"
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
variable "pass" {
  type = string
  default = "5ecur!ty_10I"
}
variable "region" {
  type = string
  default = "northcentralus"
}
variable "rg_name" {
  type = string
}
variable "ac_fqdn" {
  type = string
}
variable "ah_fqdn" {
  type = string
}
variable "eda_fqdn" {
  type = string
}
variable "db_fqdn" {
  type = string
}

# Create resource group
resource "azurerm_resource_group" "lane_rg" {
  name            = "${var.rg_name}"
  location        = "${var.region}"
  tags = {
    Vendor        = "RedHat"
    Product       = "Ansible Automation Platform"
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
  security_rule {
    name                       = "SSH_Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "140.209.216.37"
    destination_address_prefix = "*"
  }
}  

# Create the virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.rg_name}-vnet"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name
  address_space       = ["10.250.0.0/16"]
}

# Create the internal subnet
resource "azurerm_subnet" "internal" {
  name                 = "Internal"
  resource_group_name  = azurerm_resource_group.lane_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.250.1.0/24"]
}

# Assign the network security group to the Internal subnet
resource "azurerm_subnet_network_security_group_association" "nsg2subnet" {
  subnet_id      = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.nsg_int.id
}

/*
# Create the bastion host subnet
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lane_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.250.5.0/26"]
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
  #shareable_link_enabled = true
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
*/

# Create a public IP for the Controller
resource "azurerm_public_ip" "controller-publicip" {
  name                = "AC-publicIP"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Controller nic in internal subnet
resource "azurerm_network_interface" "ac-nic" {
  name                = "AC-nic"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name

  ip_configuration {
    name                          = "internal_ipcfg"
    subnet_id                     = azurerm_subnet.internal.id
    public_ip_address_id          = azurerm_public_ip.controller-publicip.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.250.1.5"
  }
}

#Create Ansbile Controller
resource "azurerm_linux_virtual_machine" "ac-vm" {
  name                = "${var.ac_fqdn}"
  resource_group_name = azurerm_resource_group.lane_rg.name
  location            = azurerm_resource_group.lane_rg.location
  size                = "Standard_D4ds_v4"
  admin_username      = "shi"
  admin_password      = "${var.pass}"
  disable_password_authentication = false
  tags                = {
    Ansible = "Controller"
  }
  network_interface_ids = [
    azurerm_network_interface.ac-nic.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = "512"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "94_gen2"
    version   = "latest"
  }
}

# Create AH nic in internal subnet
resource "azurerm_network_interface" "ah-nic" {
  name                = "AH-nic"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name

  ip_configuration {
    name                          = "internal_ipcfg"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.250.1.6"
  }
}

#Create Ansbile Automation Hub
resource "azurerm_linux_virtual_machine" "ah-vm" {
  name                = "${var.ah_fqdn}"
  resource_group_name = azurerm_resource_group.lane_rg.name
  location            = azurerm_resource_group.lane_rg.location
  size                = "Standard_D4ds_v4"
  admin_username      = "shi"
  admin_password      = "${var.pass}"
  disable_password_authentication = false
  tags                = {
    Ansible = "Automation Hub"
  }
  network_interface_ids = [
    azurerm_network_interface.ah-nic.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "94_gen2"
    version   = "latest"
  }
}

# Create EDA nic in internal subnet
resource "azurerm_network_interface" "eda-nic" {
  name                = "EDA-nic"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name

  ip_configuration {
    name                          = "internal_ipcfg"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.250.1.7"
  }
}

#Create Ansbile EDA
resource "azurerm_linux_virtual_machine" "eda-vm" {
  name                = "${var.eda_fqdn}"
  resource_group_name = azurerm_resource_group.lane_rg.name
  location            = azurerm_resource_group.lane_rg.location
  size                = "Standard_D4ds_v4"
  admin_username      = "shi"
  admin_password      = "${var.pass}"
  disable_password_authentication = false
  tags                = {
    Ansible = "Event Driven Automation"
  }
  network_interface_ids = [
    azurerm_network_interface.eda-nic.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "94_gen2"
    version   = "latest"
  }
}

# Create DB nic in internal subnet
resource "azurerm_network_interface" "db-nic" {
  name                = "DB-nic"
  location            = azurerm_resource_group.lane_rg.location
  resource_group_name = azurerm_resource_group.lane_rg.name

  ip_configuration {
    name                          = "internal_ipcfg"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.250.1.8"
  }
}

#Create Ansbile DB
resource "azurerm_linux_virtual_machine" "db-vm" {
  name                = "${var.db_fqdn}"
  resource_group_name = azurerm_resource_group.lane_rg.name
  location            = azurerm_resource_group.lane_rg.location
  size                = "Standard_D4ds_v4"
  admin_username      = "shi"
  admin_password      = "${var.pass}"
  disable_password_authentication = false
  tags                = {
    Ansible = "Database"
  }
  network_interface_ids = [
    azurerm_network_interface.db-nic.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = "512"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "94_gen2"
    version   = "latest"
  }
}