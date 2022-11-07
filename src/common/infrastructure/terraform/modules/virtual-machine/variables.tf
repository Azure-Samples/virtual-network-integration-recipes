variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "azurerm_windows_virtual_machine_admin_password" {
  type        = string
  description = "Administrative password for the Windows VM."
  sensitive   = true
}

variable "azurerm_windows_virtual_machine_admin_username" {
  type        = string
  description = "Administrative username for the Windows VM."
  sensitive   = true
}

variable "azurerm_windows_virtual_machine_name" {
  type        = string
  description = "The name of the Windows VM."
}

variable "azurerm_windows_virtual_machine_size" {
  type        = string
  default     = "Standard_D4s_v3"
  description = "The size of the Windows VM."
}

variable "azurerm_public_ip_name" {
  type        = string
  description = "The name of the public IP address assigned to the network interface card (NIC) for the Windows VM."
}
variable "azurerm_network_interface_name" {
  type        = string
  description = "The name of the network interface card (NIC) for the Windows VM."
}

variable "azurerm_network_interface_subnet_id" {
  type        = string
  description = "The ID of the virutal network subnet where this NIC should be located in."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}
