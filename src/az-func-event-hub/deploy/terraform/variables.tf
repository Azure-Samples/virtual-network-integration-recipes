variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "dns_zone_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
  default     = ""
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "resourceBaseName" {
  type        = string
  description = "The base name to be appended to all provisioned resources."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "azurerm_storage_share_name" {
  type        = string
  default     = "func-content"
  description = "Name of the Azure Files share used by Azure Functions."
}

variable "vnet_address_prefix" {
  type        = string
  description = "The IP address prefix for the virtual network."
  default     = "10.2.0.0/16"
}

variable "vnet_subnet_app_service_integration_address_prefixes" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for App Service integration."
  default     = "10.2.1.0/24"
}

variable "vnet_subnet_private_endpoints_address_prefixes" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for private endpoints."
  default     = "10.2.2.0/24"
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
