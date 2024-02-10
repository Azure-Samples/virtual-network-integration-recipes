variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "resource_base_name" {
  description = "The base name to be appended to all provisioned resources."
  default     = ""

  validation {
    condition     = length(var.resource_base_name) <= 13
    error_message = "The 'resource_base_name' value must be less than or equal to 13 characters."
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

variable "synapse_sql_administrator_login" {
  type        = string
  description = "Specifies The login name of the SQL administrator."
}

variable "synapse_sql_administrator_login_password" {
  type        = string
  description = "The Password associated with the sql_administrator_login for the SQL administrator."
}

variable "virtual_network_address_prefix" {
  type        = string
  description = "The IP address prefix for the virtual network."
  default     = "10.1.0.0/16"
}

variable "bastion_subnet_address_prefix" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for Azure Bastion integration."
  default     = "10.1.1.0/26"
}

variable "private_endpoint_subnet_address_prefix" {
  type        = string
  description = "The IP address prefix for the virtual network subnet used for private endpoints."
  default     = "10.1.0.0/26"
}

variable "integrate_with_hub" {
  type        = bool
  description = "Indicate if this recipe is being integrated with centrally deployed hub (in same or different subscription/resource group)."
  default     = false
}

variable "hub_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
}

variable "hub_virtual_network_name" {
  type        = string
  description = "The name of virtual network where the self hosted agent is deployed in the Hub."
}

variable "hub_subscription_id" {
  type        = string
  description = "The subscription id of the Hub."
}
