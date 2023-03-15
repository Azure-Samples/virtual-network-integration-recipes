variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "azurerm_purview_principal_id" {
  type        = string
  description = "Azure Purview principal id."
}

variable "storage_account_name" {
  type        = string
  description = "Specifies the Storage account name"
}

variable "default_container_name" {
  type        = string
  description = "Specifies the default container name of the storage container"
}

variable "pe_subnet_id" {
  description = "Private endpoint subnet Id"
}

variable "pe_base_name" {
  type        = string
  description = "Private endpoint base name."
}

variable "private_dns_zone_ids" {
  type        = map(string)
  description = "Private DNS zone ids."
}

variable "private_dns_names_map_for_storage" {
  type        = map(string)
  description = "Private DNS map links for storage"
}
