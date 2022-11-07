resource "azurerm_network_interface" "nic" {
  name                = var.azurerm_network_interface_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = var.azurerm_network_interface_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                = var.azurerm_public_ip_name
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  location            = var.location
  sku                 = "Basic"
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdownvm" {
  location              = var.location
  virtual_machine_id    = azurerm_windows_virtual_machine.vm.id
  enabled               = true
  tags                  = var.tags
  daily_recurrence_time = "1900"
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.azurerm_windows_virtual_machine_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  size                = var.azurerm_windows_virtual_machine_size
  admin_password      = var.azurerm_windows_virtual_machine_admin_password
  admin_username      = var.azurerm_windows_virtual_machine_admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  license_type = "Windows_Client"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-pro-g2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "aadLoginExtension" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}
