
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "azurerm_bastion_host_name" {
  type        = string
  description = "Specifies the name of the Bastion Host."
}

variable "azurerm_bastion_host_subnet_id" {
  type        = string
  description = "Reference to a subnet in which this Bastion Host has been created."
}

variable "azurerm_public_ip_name" {
  type        = string
  description = "The name of the public IP address."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

