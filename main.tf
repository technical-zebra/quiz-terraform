terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "quiz-rg" {
  name     = "quiz-resources"
  location = "East Asia"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "quiz-vn" {
  name                = "quiz-network"
  resource_group_name = azurerm_resource_group.quiz-rg.name
  location            = azurerm_resource_group.quiz-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "quiz-subnet" {
  name                 = "quiz-subnet"
  resource_group_name  = azurerm_resource_group.quiz-rg.name
  virtual_network_name = azurerm_virtual_network.quiz-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "quiz-sg" {
  name                = "quiz-sg"
  location            = azurerm_resource_group.quiz-rg.location
  resource_group_name = azurerm_resource_group.quiz-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "quiz-dev-rule" {
  name                        = "quiz-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.quiz-rg.name
  network_security_group_name = azurerm_network_security_group.quiz-sg.name
}

resource "azurerm_subnet_network_security_group_association" "quiz-sga" {
  subnet_id                 = azurerm_subnet.quiz-subnet.id
  network_security_group_id = azurerm_network_security_group.quiz-sg.id
}

resource "azurerm_public_ip" "quiz-ip" {
  name                    = "quiz-ip"
  location                = azurerm_resource_group.quiz-rg.location
  resource_group_name     = azurerm_resource_group.quiz-rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "quiz-nic" {
  name                = "quiz-nic"
  location            = azurerm_resource_group.quiz-rg.location
  resource_group_name = azurerm_resource_group.quiz-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.quiz-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.quiz-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "quiz-vm" {
  name                = "quiz-vm"
  resource_group_name = azurerm_resource_group.quiz-rg.name
  location            = azurerm_resource_group.quiz-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.quiz-nic.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/quizazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
      command = templatefile("windows-ssh-script.tpl",{
          hostname = self.public_ip_address,
          user = "adminuser",
          identityfile = "~/.ssh/quizazurekey"

      })
      interpreter = ["Powershell", "-Command"]
  }

  tags = {
    environment = "dev"
  }
}