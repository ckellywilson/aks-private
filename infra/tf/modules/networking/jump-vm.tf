# Jump VM for accessing private AKS cluster via Azure Bastion
# This VM provides a secure entry point into the VNet for kubectl operations

# Generate SSH key pair for the jump VM
resource "tls_private_key" "jump_vm" {
  count = var.private_cluster_enabled ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Network Interface for Jump VM
resource "azurerm_network_interface" "jump_vm" {
  count = var.private_cluster_enabled ? 1 : 0

  name                = "nic-${var.jump_vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Jump VM for Bastion access
resource "azurerm_linux_virtual_machine" "jump_vm" {
  count = var.private_cluster_enabled ? 1 : 0

  name                = var.jump_vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.jump_vm_size
  admin_username      = var.jump_vm_admin_username
  tags                = var.tags

  # Enable both password and SSH key authentication
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.jump_vm[0].id,
  ]

  admin_ssh_key {
    username   = var.jump_vm_admin_username
    public_key = tls_private_key.jump_vm[0].public_key_openssh
  }

  # Set a default password for convenience (change this in production)
  admin_password = var.jump_vm_admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Use Ubuntu 22.04 LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init script to install required tools
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username = var.jump_vm_admin_username
  }))
}

# SSH private key will be output for manual storage
# In production, consider storing in Azure Key Vault
