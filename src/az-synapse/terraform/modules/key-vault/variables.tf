variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "base_name" {
  type = string
  description = "The base name to be appended to all provisioned resources."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "key_vault_name" {
  type        = string
  description = "The name of the key vault."
}

variable "synapse_workspace_tenant_id" {
  type        = string
  description = "Azure synapse workspase tenant id."
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant Id."
}

variable "synapse_workspace_principal_id" {
  type        = string
  description = "Azure synapse workspase principle id."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone id."
}

variable "key_vault_private_endpoint_name" {
  type        = string
  description = "Azure key vault private endpoint name."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Private endpoint subnet id."
}
