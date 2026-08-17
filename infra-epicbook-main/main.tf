terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

# Random suffix for globally unique MySQL server name
resource "random_string" "mysql_suffix" {
  length  = 6
  upper   = false
  special = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "epic-book-rg"
  location = "South Africa North"

  tags = {
    Name = "${var.resource_prefix}-rg"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Name = "${var.resource_prefix}-vnet"
  }
}

# Web subnet for VM
resource "azurerm_subnet" "web" {
  name                 = "${var.resource_prefix}-web-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Delegated DB subnet for Azure MySQL Flexible Server
resource "azurerm_subnet" "db" {
  name                 = "${var.resource_prefix}-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "mysql-flexible-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Network Security Group for VM
resource "azurerm_network_security_group" "main" {
  name                = "${var.resource_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.resource_prefix}-nsg"
  }
}

# Associate NSG with web subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Public IP for VM
resource "azurerm_public_ip" "main" {
  name                = "${var.resource_prefix}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "${var.resource_prefix}-pip"
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.resource_prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = {
    Name = "${var.resource_prefix}-nic"
  }
}

# Private DNS zone for MySQL Flexible Server
resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.resource_prefix}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Name = "${var.resource_prefix}-mysql-dns"
  }
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${var.resource_prefix}-mysql-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = {
    Name = "${var.resource_prefix}-mysql-dns-link"
  }
}

# Linux VM with SSH key-based authentication
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.resource_prefix}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2ats_v2"
  admin_username      = var.admin_username

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.public_key))
  }

  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  os_disk {
    name                 = "${var.resource_prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name = "${var.resource_prefix}-vm"

  tags = {
    Name = "${var.resource_prefix}-vm"
  }
}

# Azure MySQL Flexible Server (private access)
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "${var.resource_prefix}-mysql-${random_string.mysql_suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = var.db_user
  administrator_password = var.db_password
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.db.id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"

# Fix: pin the actual zone from Azure
  zone = "2"

  # Fix: prevent Terraform from attempting zone updates on reruns
  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]

  tags = {
    Name = "${var.resource_prefix}-mysql"
  }
}

# Database inside MySQL server
resource "azurerm_mysql_flexible_database" "main" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}