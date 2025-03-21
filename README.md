# Terraform-Azure
Replace xxx with your subscription id
Replace yyy with principal id
Replace zzz with tenant id


Title: "Automating Azure Infrastructure with Terraform: A Real-World Example"

 In this article, I'll share a real-world example of how to use Terraform  to create a complete Azure infrastructure, including a resource group, virtual network, subnet, public IP, network security group, and virtual machine.
This Terraform code provisions a Red Hat Enterprise Linux (RHEL) virtual machine (VM) on Azure, along with associated resources like network interfaces, security groups, and SSH keys. I'll break down each resource and highlight best practices implemented in the code:

What is terraform?
Terraform is a tool that helps you create and manage computer resources, like virtual machines, networks, and databases, in a safe and efficient way and automated way, it is a Infrastructure as code tool.
1. Version control: Terraform configurations can be version-controlled, allowing for tracking changes and collaboration.
2. Reusability: Terraform configurations can be reused across multiple environments and projects.


1. Providers and Authentication
- The code uses the azuread and azurerm providers for Azure Active Directory and Azure Resource Manager, respectively.
- Authentication is handled using the Azure CLI credentials (use_msi = false).
- Best practice: Using Azure CLI credentials for authentication is a good practice, as it allows for seamless integration with Azure services.

2. Azure AD Application and Service Principal
- The code creates an Azure AD application (azuread_application) and a service principal (azuread_service_principal) for the application.
- A password is generated for the service principal using azuread_service_principal_password.
- Best practice: Creating a separate service principal for the application allows for fine-grained access control and reduces the risk of credential compromise.

3. Role Assignment
- The code assigns the Contributor role to the service principal at the subscription level using azurerm_role_assignment.
- Best practice: Assigning the minimum required permissions (in this case, Contributor) ensures that the service principal has only the necessary access to perform its tasks.

4. SSH Key Generation
- The code generates an SSH key pair using tls_private_key.
- Best practice: Generating a new SSH key pair for each deployment ensures that each VM has a unique key pair, reducing the risk of key compromise.

5. Resource Group
- The code creates a resource group (azurerm_resource_group) to hold all the resources.
- Best practice: Using a separate resource group for each deployment allows for easy management, monitoring, and cleanup of resources.

6. Virtual Network and Subnet
- The code creates a virtual network (azurerm_virtual_network) and a subnet (azurerm_subnet) for the VM.
- Best practice: Using a separate virtual network and subnet for each deployment allows for network isolation and reduces the risk of network conflicts.

7. Public IP and Network Security Group
- The code creates a public IP address (azurerm_public_ip) and a network security group (azurerm_network_security_group) for the VM.
- The NSG allows inbound SSH traffic on port 22.
- Best practice: Using a public IP address and an NSG allows for controlled access to the VM, while also providing a public IP address for external connectivity.

8. Network Interface
- The code creates a network interface (azurerm_network_interface) for the VM, associating it with the subnet, public IP address, and NSG.
- Best practice: Using a separate network interface for each VM allows for flexible network configuration and reduces the risk of network conflicts.

9. Virtual Machine
- The code creates a RHEL VM (azurerm_linux_virtual_machine) using the generated SSH key pair and associates it with the network interface.
- Best practice: Using a Linux VM and generating a new SSH key pair for each deployment ensures secure access to the VM.

10. Local File (SSH Private Key)
- The code saves the SSH private key to a local file (local_file) for easy access.
- Best practice: Saving the SSH private key to a secure location allows for easy access to the VM, while also reducing the risk of key compromise.

Overall, this code implements several best practices, including:

- Using Azure CLI credentials for authentication
- Creating a separate service principal for the application
- Assigning the minimum required permissions
- Generating a new SSH key pair for each deployment
- Using a separate resource group, virtual network, and subnet for each deployment
- Using a public IP address and an NSG for controlled access to the VM
- Saving the SSH private key to a secure location


Terraform Code:

In my code I have use two provider .
The reason for having two separate provider "azurerm" blocks is to use different authentication methods:

1. First block (alias = "cli"): This block uses the Azure CLI credentials (use_msi = false) to authenticate with Azure. This is used for the initial setup, such as creating the resource group, Azure AD application, and service principal.
2. Second block: This block uses the client ID, client secret, and tenant ID from the Azure AD application and service principal created earlier. This is used for subsequent resource creations, such as the virtual network, subnet, and virtual machine.

By using two separate provider "azurerm" blocks, you're able to:

- Use Azure CLI credentials for the initial setup
- Use the Azure AD application and service principal credentials for resource creation to have fine grained access control.

terraform
provider "azurerm" {
  alias = "cli"
  features {}
  subscription_id = "xxx"
  // Use Azure CLI credentials
  use_msi = false
}

// ...

provider "azurerm" {
  features {}
  subscription_id = "xxx"
  client_id = azuread_application.first_project.client_id
  client_secret = azuread_service_principal_password.password.value
  tenant_id = "xxx"
}



The Terraform code consists of several resources, including:

1. Azure AD Application: 
    What/Why: Application or Service that uses Azure AD for authentication and authorization. 
    Registers an application with Azure AD to enable authentication, authorization, and role-based access for automated resource management.
    
Creates an Azure AD application with a display name.
# Create an Azure AD application
resource "azuread_application" "first_project" {
  display_name = "first_project"
}

2. Azure AD Service Principal: 
    what/why: Creates a managed identity for an application, enabling it to authenticate and access Azure resources without user interaction or password.
Creates an Azure AD service principal with a client ID.
# Create a service principal for the application
resource "azuread_service_principal" "user_1" {
  client_id = azuread_application.first_project.client_id
}

3. Azure AD Service Principal Password: 
Creates a password for the service principal.
# Set a password for the service principal
resource "azuread_service_principal_password" "password" {
  service_principal_id = azuread_service_principal.user_1.id
  end_date             = "2025-06-30T23:59:59Z"
}

4. Azure Role Assignment: 
Grants the service principal "Contributor" role, allowing it to create, manage, and delete Azure resources within the assigned scope.
Assigns the Contributor role to the service principal.
resource "azurerm_role_assignment" "example" {
  provider =             azurerm.cli
  scope                = "/subscriptions/xxx"
  role_definition_name = "Contributor"
  principal_id         = "yyy"
}

5. Resource Group: 
Resource Group: Organizes and manages related Azure resources, providing a logical container for deployment, management, and billing purposes.
Creates a resource group with a specified name and location.
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "East US"
  depends_on = [azurerm_role_assignment.example]
}

6. Virtual Network: 
Virtual Network: Enables secure, isolated communication between Azure resources by creating a virtualized network with a defined address space and location.
Creates a virtual network with a specified address space and location.
resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

7. Subnet:
Subnet: Divides a virtual network into smaller, manageable segments, enabling organized and secure communication between Azure resources.
 Creates a subnet with a specified address prefix and location.
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

8. Public IP: 
Public IP: Assigns a unique, publicly accessible IP address to an Azure resource for inbound and outbound communication.
Creates a public IP address with a specified allocation method.
resource "azurerm_public_ip" "public_ip" {
  name                = "myPublicIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}


9. Network Security Group: 
Controls and filters incoming and outgoing network traffic to Azure resources based on specified security rules.
Creates a network security group with a specified security rule.
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

10. Network Interface: 
Connects a virtual machine to a virtual network, enabling communication between the VM and other resources.
Creates a network interface with a specified IP configuration.
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
Associates a Network Security Group (NSG) with a Network Interface (NIC).
This association enables the NSG's security rules to be applied to the traffic flowing through the NIC, providing an additional layer of security to the virtual machine or other resources connected to the NIC.

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

	11.  Generate SSH Key**
	resource "tls_private_key" "ssh_key" {
	  algorithm = "RSA"
	  rsa_bits  = 2048
	}

12. Virtual Machine: 
Creates a virtual machine with a specified size, admin username, and network interface ID.
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
    sku       = "8.1"# Adjust if necessary
    version   = "latest"
  }
}

	13. Save SSH key locally
   resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/id_rsa"
}

	14. Display public ip and key file location.
output "vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "ssh_private_key_path" {
  value = local_file.private_key.filename
}


Highlights:

- Uses Azure AD authentication to create resources.
- Creates a complete Azure infrastructure, including networking and security resources.
- Highlights the importance of security and networking in Azure infrastructure deployment.

Conclusion:

This Terraform code demonstrates the power of automation in deploying Azure infrastructure. By using Terraform, you can create complete infrastructure environments with ease, including networking and security resources.
In the Next article I 'll be modularize the code for better management and reusable.



![image](https://github.com/user-attachments/assets/6b6cb793-2ab7-433c-9a05-ea13d9fdec91)
