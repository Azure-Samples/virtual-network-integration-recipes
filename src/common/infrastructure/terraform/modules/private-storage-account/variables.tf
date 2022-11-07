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

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "azurerm_storage_account_name" {
  type        = string
  description = " Specifies the name of the storage account."
}

variable "azurerm_storage_account_account_tier" {
  type        = string
  default     = "Standard"
  description = "Specifies the tier to use for this storage account."
}

variable "azurerm_storage_account_account_kind" {
  type        = string
  default     = "StorageV2"
  description = "Specifies the kind to use for this storage account."
}

variable "azurerm_storage_account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Specifies the type of replication to use for this storage account."
}

variable "azurerm_private_endpoint_storage_blob_name" {
  type        = string
  description = "Specifies the name for the Azure storage account's private endpoint for the blob resource."
}

variable "azurerm_private_endpoint_storage_table_name" {
  type        = string
  description = "Specifies the name for the Azure storage account's private endpoint for the table resource."
}

variable "azurerm_private_endpoint_storage_queue_name" {
  type        = string
  description = "Specifies the name for the Azure storage account's private endpoint for the queue resource."
}

variable "azurerm_private_endpoint_storage_file_name" {
  type        = string
  description = "Specifies the name for the Azure storage account's private endpoint for the file resource."
}

variable "azurerm_private_endpoint_storage_endpoint_subnet_id" {
  type        = string
  description = "Specifies the virtual network subnet ID from which to obtain IP address for the private endpoint."
}

variable "azurerm_private_dns_zone_virtual_network_id" {
  type        = string
  description = "Specifies the virtual network ID used in connecting the private endpoints."
}

variable "azurerm_private_endpoint_storage_table_service_connection_name" {
  type        = string
  description = "Specifies the name for the private endpoint for the Azure storage table resource."
}

variable "azurerm_private_endpoint_storage_file_service_connection_name" {
  type        = string
  description = "Specifies the name for the private endpoint for the Azure storage file resource."
}

variable "azurerm_private_endpoint_storage_queue_service_connection_name" {
  type        = string
  description = "Specifies the name for the private endpoint for the Azure storage queue resource."
}

variable "azurerm_private_endpoint_storage_blob_service_connection_name" {
  type        = string
  description = "Specifies the name for the private endpoint for the Azure storage blob resource."
}
