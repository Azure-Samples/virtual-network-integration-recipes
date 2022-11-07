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

variable "azurerm_application_insights_name" {
  type        = string
  description = "Specifies the name of the Application Insights resource."
}

variable "azurerm_log_analytics_workspace_name" {
  type        = string
  description = "Specifies the name of the Log Analytics Workspace resource."
}
