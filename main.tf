terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.50.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}


resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-PublicIp2"
  resource_group_name = "${var.prefix}-codehub-reg"
  location            = var.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}



resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-codehub-nic2"
  location            = var.location
  resource_group_name = "${var.prefix}-codehub-reg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/139a319c-df00-476d-9252-94623e31323f/resourceGroups/Regen-Project-codehub-reg/providers/Microsoft.Network/virtualNetworks/Regen-Project-codehub-network/subnets/Regen-Project-codehub-subnetwork"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}


resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_ssh_public_key" "worker-key" {
  name                = "worker-key"
  resource_group_name = "${var.prefix}-codehub-reg"
  location            = var.location
  public_key          = tls_private_key.example_ssh.public_key_openssh
}


resource "azurerm_linux_virtual_machine" "main" {
  name                  = "${var.prefix}-vm-node"
  location              = var.location
  resource_group_name   = "${var.prefix}-codehub-reg"
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_B1s"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "hostname"
  admin_username = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  tags = {
    environment = "staging"
  }

  # Run a command on the local machine to create a file containing the private key
  provisioner "local-exec" {
    command = "sudo terraform output -raw ${tls_private_key.example_ssh.private_key_openssh} > id_rsa"
  }
}

  output "private_key" {
  value     = tls_private_key.example_ssh.private_key_openssh
  }


variable "location" {}
variable "prefix" {}
variable "admin_username"{}
variable "admin_password"{}
