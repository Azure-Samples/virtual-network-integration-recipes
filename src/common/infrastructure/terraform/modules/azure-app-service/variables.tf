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

variable "azurerm_app_service_plan_name" {
  type        = string
  description = "The name of the App Service plan."
}

variable "azurerm_app_service_plan_size" {
  type        = string
  description = "The size of the App Service plan."
  default     = "P1v3"
}

variable "azurerm_app_service_plan_tier" {
  type        = string
  description = "The tier of the App Service plan."
  default     = "PremiumV3"
}

variable "azurerm_app_service_app_name" {
  type        = string
  description = "The name of the App Service."
}

variable "azurerm_app_service_appinsights_instrumentation_key" {
  type        = string
  description = "The Application Insights instrumentation key used by the App Service."
  sensitive   = true
}

variable "azurerm_app_service_virtual_network_integration_subnet_id" {
  type        = string
  description = "The ID for the virtual network subnet used for virtual network integration."
}
