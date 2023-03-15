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

variable "storage_account_names" {
  type        = map(string)
  description = "The storage acounts that need to be created."
}

variable "default_container_name" {
  type        = string
  description = "Storage container name for the Data Lake Gen2."
  default     = "container001"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Private endpoint subnet id."
}

variable "private_dns_zone_ids" {
  type        = map(string)
  description = "Private DNS zone ids."
}

variable "private_dns_names" {
  type        = map(string)
  description = "Private DNS map links for storage"
}
