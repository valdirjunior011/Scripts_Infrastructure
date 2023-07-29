# Set up Azure provider
provider "azurerm" {
  features {}
}

# Create 10 virtual machines
resource "azurerm_virtual_machine" "example_vm" {
  count                 = 10
  name                  = "ExampleVM-${count.index + 1}"
  location              = "East US"  # Replace with your desired location
  resource_group_name   = "example_rg"  # Replace with your desired resource group name
  network_interface_ids = [azurerm_network_interface.example_nic[count.index].id]
  vm_size               = "Standard_B1s"  # Replace with your desired VM size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "exampleosdisk-${count.index + 1}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment = "production"
  }
}

# Create 10 network interfaces
resource "azurerm_network_interface" "example_nic" {
  count               = 10
  name                = "ExampleNIC-${count.index + 1}"
  location            = "East US"  # Replace with your desired location
  resource_group_name = "example_rg"  # Replace with your desired resource group name

  ip_configuration {
    name                          = "ExampleNICConfig"
    subnet_id                     = azurerm_subnet.example_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Example subnet (Required for the network interfaces)
resource "azurerm_subnet" "example_subnet" {
  name                 = "ExampleSubnet"
  resource_group_name  = "example_rg"  # Replace with your desired resource group name
  virtual_network_name = azurerm_virtual_network.example_vnet.name
  address_prefixes     = ["10.0.2.0/24"]  # Replace with your desired subnet CIDR block
}

# Example virtual network (Required for the network interfaces)
resource "azurerm_virtual_network" "example_vnet" {
  name                = "ExampleVNET"
  location            = "East US"  # Replace with your desired location
  resource_group_name = "example_rg"  # Replace with your desired resource group name
  address_space       = ["10.0.0.0/16"]  # Replace with your desired VNET CIDR block
}
