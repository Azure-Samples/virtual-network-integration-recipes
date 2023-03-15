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

variable "virtual_network_name" {
  type        = string
  description = "The name of the virtual network."
}

variable "private_endpoint_subnet_name" {
  type        = string
  description = "The name of the virtual network subnet to be used for private endpoints."
}

variable "azure_bastion_subnet_name" {
  type        = string
  description = "The name of the subnet for Azure Bastions"
  default     = "AzureBastionSubnet"
}

variable "virtual_network_address_prefix" {
  type        = string
  description = "The virtual network IP space to use for the new virutal network."
}

variable "private_endpoint_subnet_address_prefix" {
  type        = string
  description = "The IP space to use for the subnet for private endpoints."
}

variable "bastion_subnet_address_prefix" {
  type        = string
  description = "The IP space to use for the AzureBastionSubnet subnet."
}
