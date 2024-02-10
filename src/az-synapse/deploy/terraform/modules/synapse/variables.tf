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

variable "base_name" {
  type = string
  description = "The base name to be appended to all provisioned resources."
}

variable "synapse_workspace_name" {
  type        = string
  description = "Azure Synapse workspace name."
}

variable "synapse_storage_account_id" {
  type        = string
  description = "Azure Synapse ALDS gen2 Storage account Id."
}

variable "synapse_storage_file_system_id" {
  type        = string
  description = "Azure Synapse ALDS gen2 Storage account file system Id."
}

variable "main_storage_account_id" {
  type        = string
  description = "Application ALDS gen2 Storage account Id."
}

variable "synapse_sql_administrator_login" {
  type        = string
  description = "Specifies the login name of the SQL administrator."
}

variable "synapse_sql_administrator_login_password" {
  type        = string
  description = "The password associated with the sql_administrator_login for the SQL administrator."
}

variable "synapse_managed_resource_group_name" {
  type        = string
  description = "The resource group where the synapse managed resources will be created."
}

variable "synapse_private_link_hub_name" {
  type        = string
  description = "Azure Synapse private link hub name."
}

variable "synapse_spark_pool_name" {
  type        = string
  description = "Syanpse Spark Pool name."
  default     = "synsp001"
}

variable "synapse_sql_pool_name" {
  type        = string
  description = "Synapse SQL Pool name."
  default     = "syndp001"
}

variable "private_dns_zone_ids" {
  type        = map(string)
  description = "Private DNS zone id."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Private endpoint subnet id."
}

variable "synapse_private_dns_zone_map" {
  type        = map(string)
  description = "Private DNS zone map for Azure Synapse."
}
