variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "dns_zone_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
}

variable "dns_zone_resource_group_subscription_id" {
  type        = string
  description = "The subscription id of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "vnet_address_prefix" {
  type        = string
  description = "The IP address prefix for the virtual network."
  default     = "10.14.0.0/16"
}

variable "bastion_subnet_address_prefix" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for Azure Bastion integration."
  default     = "10.14.1.0/24"
}

variable "private_endpoint_subnet_address_prefix" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for private endpoints."
  default     = "10.14.0.0/24"
}

variable "new_or_existing_dns_zones" {
  type        = string
  description = "Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones."
  default     = "new"
  validation {
    condition     = contains(["new", "existing"], var.new_or_existing_dns_zones)
    error_message = "Value must be either 'new' or 'existing'."
  }
}
