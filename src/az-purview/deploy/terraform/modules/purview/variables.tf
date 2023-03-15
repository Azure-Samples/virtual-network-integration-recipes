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

variable "purview_account_name" {
  type        = string
  description = "Specifies the Purview account name"
}

variable "pe_base_name" {
  type        = string
  description = "Private endpoint base name."
}

variable "private_endpoint_subnet_id" {
  description = "Specifies the Private endpoint subnet id"
}

variable "purview_private_dns_zone_id_map" {
  type        = map(any)
  description = "Map for purview dns zone ids to services mapping"
}
