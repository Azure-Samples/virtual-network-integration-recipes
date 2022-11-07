variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "dns_zone_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
}

variable "newOrExistingDnsZones" {
  type        = string
  description = "Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones."
  default     = "new"
  validation {
    condition     = contains(["new", "existing"], var.newOrExistingDnsZones)
    error_message = "Value must be either 'new' or 'existing'."
  }
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "key_vault_name" {
  type        = string
  description = "The name of the key vault."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "azurerm_private_endpoint_kv_private_endpoint_name" {
  type        = string
  description = "Specifies the name of the key vault private endpoint."
}

variable "azurerm_private_endpoint_kv_private_endpoint_subnet_id" {
  type        = string
  description = "Specifies the ID of the virtual network subnet from which private IP addresses will be allocated for the private endpoint."
}

variable "azurerm_private_endpoint_kv_private_endpoint_service_connection_name" {
  type        = string
  description = "Specifies the name for the private endpoint connection for the key vault. "
}

variable "azurerm_private_dns_zone_virtual_network_id" {
  type        = string
  description = "Specifies the ID of the virtual network that should be linked to the DNS Zone."
}
