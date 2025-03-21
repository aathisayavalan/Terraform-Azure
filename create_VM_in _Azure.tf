terraform {
required_providers {
   azuread = {
      source  = "hashicorp/azuread"
      
}
azurerm = {
      source  = "hashicorp/azurerm"
    
}
}
}

provider "azuread" {  
  
} 

provider "azurerm" {
  alias = "cli"
  features {}
  subscription_id = "03cdf759-aa97-4e94-ab63-5acfd7554436"
  // Use Azure CLI credentials
  use_msi = false
}
resource "azuread_application" "first_project" {
  display_name = "first_project"
}

#output "application_attributes" {
 # value = azuread_application.first_project
#



resource "azuread_service_principal" "user_1" {
  client_id = azuread_application.first_project.client_id
}

resource "azuread_service_principal_password" "password" {
  service_principal_id = azuread_service_principal.user_1.id
  end_date             = "2025-06-30T23:59:59Z"
}
output "client_id" {
  value = azuread_application.first_project.client_id
}
output "client_secret" {
  value = azuread_service_principal_password.password.value
   sensitive = true
}


resource "azurerm_role_assignment" "example" {
  provider =             azurerm.cli
  scope                = "/subscriptions/03cdf759-aa97-4e94-ab63-5acfd7554436"
  role_definition_name = "Contributor"
  principal_id         = "814659b3-bb65-4b34-a474-59163ac612d5"
}


  provider "azurerm" {
  features {}
  subscription_id = "03cdf759-aa97-4e94-ab63-5acfd7554436"
  client_id       = azuread_application.first_project.client_id
  client_secret   = azuread_service_principal_password.password.value
  tenant_id       = "b07c1c33-9f80-4baa-8a5b-9d080376d3a8"
}

# **1. Generate SSH Key**
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# **2. Resource Group**
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "East US"
  depends_on = [azurerm_role_assignment.example]
}

# **3. Virtual Network**
resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# **4. Subnet**
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# **5. Public IP**
resource "azurerm_public_ip" "public_ip" {
  name                = "myPublicIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

# **6. Network Security Group**
resource "azurerm_network_security_group" "nsg" {
  name                = "myNSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# **7. Network Interface**
resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
    
  }


  
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# **8. Virtual Machine**
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "myRedHatVM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.1" # Adjust if necessary
    version   = "latest"
  }
}

# **9. Save SSH Key Locally**
resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/id_rsa"
}

output "vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "ssh_private_key_path" {
  value = local_file.private_key.filename
}


