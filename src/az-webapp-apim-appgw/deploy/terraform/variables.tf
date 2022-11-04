variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "dns_zone_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
}

variable "resourceBaseName" {
  description = "The base name to be appended to all provisioned resources."
  type        = string
  default     = ""
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
  default     = "10.8.0.0/16"
}

variable "vnet_subnet_app_service_integration_address_prefixes" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for App Service integration."
  default     = "10.8.1.0/24"
}

variable "vnet_subnet_private_endpoints_address_prefixes" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for private endpoints."
  default     = "10.8.2.0/24"
}

variable "vnet_subnet_appgw_adddress_prefixes" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for Application Gateway."
  default     = "10.8.3.0/24"
}

variable "vnet_subnet_apim_adddress_prefixes" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for API Management."
  default     = "10.8.4.0/24"
}

variable "azurerm_api_management_publisher_name" {
  type        = string
  description = "The name of publisher/company."
  default     = "Contoso"
}

variable "azurerm_api_management_publisher_email" {
  type        = string
  description = "The email of publisher/company."
  default     = "publisheremail@contoso.com"
}

variable "azurerm_api_management_sku_name" {
  type        = string
  description = "A string consisting of two parts separated by an underscore(_). The first part is the name, valid values include: Consumption, Developer, Basic, Standard and Premium. The second part is the capacity (e.g. the number of deployed units of the sku), which must be a positive integer (e.g. Developer_1)."
  default     = "Developer_1"
}

# variable "azurerm_public_ip_availability_zone_appgw" {
#   type        = string
#   description = "The availability zone in which to allocate the Public IP."
#   default     = ""
# }

variable "custom_domain" {
  type        = string
  description = "The name of the of domain to use in API Management custom domains."
}

variable "gateway_custom_domain_hostname" {
  type        = string
  description = "Hostname for the API Management gateway custom domain."
}

variable "gateway_custom_domain_certificate" {
  type        = string
  description = "Base64 encoded certificate (.pfx) for the API Management gateway custom domain."
  sensitive   = true
}

variable "portal_custom_domain_hostname" {
  type        = string
  description = "Hostname for the API Management portal custom domain."
}

variable "portal_custom_domain_certificate" {
  type        = string
  description = "Base64 encoded certificate (.pfx) for the API Management portal custom domain."
  sensitive   = true
}

variable "management_custom_domain_hostname" {
  type        = string
  description = "Hostname for the API Management management custom domain."
}

variable "management_custom_domain_certificate" {
  type        = string
  description = "Base64 encoded certificate (.pfx) for the API Management management custom domain."
  sensitive   = true
}

variable "trusted_root_certificate" {
  type        = string
  description = "Base64 encoded root certificate (.cer)."
  sensitive   = true
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
