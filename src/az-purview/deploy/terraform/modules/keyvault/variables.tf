variable "resource_group_name" {
  description = "Resource Group name to host keyvault"
  type        = string
}

variable "location" {
  description = "key vault location"
  type        = string
}

variable "keyvault_sku_name" {
  description = "keyvault sku - potential values Standard and Premium"
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Key vault tags"
  type        = map(string)
}

variable "key_vault_name" {
  description = "Key vault name"
  type        = string
}

variable "azurerm_purview_tenant_id" {
  type        = string
  description = "Azure Purview tenant id."
}

variable "azurerm_purview_principal_id" {
  type        = string
  description = "Azure Purview principal id."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone id."
}

variable "azurerm_pe_kv_name" {
  type        = string
  description = "Azure key vault private endpoint name."
}

variable "pe_subnet_id" {
  type        = string
  description = "Private endpoint subnet id."
}

variable "azurerm_pe_kv_service_connection_name" {
  type        = string
  description = "Private endpoint service connection name."
  default     = "kv-private-service-connection"
}
