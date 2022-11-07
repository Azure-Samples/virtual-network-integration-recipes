variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "dns_zone_resource_group_name" {
  type        = string
  description = "value"
  default     = "The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints."
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

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "azurerm_eventhub_namespace_name" {
  type        = string
  description = "Specifies the name of the Event Hub namespace."
}

variable "azurerm_eventhub_namespace_sku" {
  type        = string
  default     = "Standard"
  description = "Specifies the Event Hub namespace tier to use."
}

variable "azurerm_eventhub_namespace_subnet_id" {
  type        = string
  description = "Specifies the virtual network subnet ID to allow access to the event hub."
}

variable "azurerm_eventhub_name" {
  type        = string
  description = "Specifies the name of the event hub."
}

variable "azurerm_eventhub_partition_count" {
  type        = number
  default     = 32
  description = "Specifies the current number of shards on the Event Hub."
}

variable "azurerm_eventhub_message_retention" {
  type        = number
  default     = 1
  description = "Specifies the number of days to retain the events for this Event Hub."
}

variable "azurerm_private_endpoint_evhns_private_endpoint_name" {
  type        = string
  description = "Specifies the name of the Event Hub namespace private endpoint."
}

variable "azurerm_private_endpoint_evhns_private_endpoint_subnet_id" {
  type        = string
  description = "Specifies the ID of the virtual network subnet from which private IP addresses will be allocated for the private endpoint."
}

variable "azurerm_private_endpoint_evhns_private_endpoint_service_connection_name" {
  type        = string
  description = "Specifies the name for the private endpoint connection for the Event Hub namespace. "
}

variable "azurerm_private_dns_zone_virtual_network_id" {
  type        = string
  description = "Specifies the ID of the virtual network that should be linked to the DNS Zone."
}
