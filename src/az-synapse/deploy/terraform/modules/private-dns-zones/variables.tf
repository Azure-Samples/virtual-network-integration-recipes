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

variable "private_dns_names_map" {
  type        = map(any)
  description = "The Private DNS Zone names"
}

variable "integrate_with_hub" {
  type        = bool
  description = "Indicate if this recipe is being integrated with centrally deployed hub (in same or different subscription/resource group)."
  default     = false
}

variable "dns_zone_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
}

variable "dns_zone_resource_group_subscription_id" {
  type        = string
  description = "The subscription id of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
}
