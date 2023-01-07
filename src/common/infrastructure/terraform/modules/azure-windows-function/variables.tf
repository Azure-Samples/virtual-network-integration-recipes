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

variable "is_linux" {
  type        = bool
  description = "Determines if the App Service Plan will be Linux or Windows."
  default     = false
}

variable "linux_fx_version" {
  type        = string
  description = "Linux App Framework and version for the App Service."
  default     = "DOTNETCORE|3.1"
}

variable "azurerm_service_plan_name" {
  type        = string
  description = "The name of the App Service plan."
}

variable "azurerm_windows_function_app_name" {
  type        = string
  description = "The name of the function app."
}

variable "azurerm_windows_function_app_storage_account_name" {
  type        = string
  description = "The Azure storage account name which will be used by the function app."
}

# variable "azurerm_windows_function_app_storage_account_access_key" {
#   type        = string
#   description = "The access key which will be used to access the Azure storage account for the function app."
#   sensitive   = true
# }

variable "azurerm_windows_function_app_application_insights_connection_string" {
  type        = string
  description = "The Application Insights instrumentation key used by the function app."
  sensitive   = true
}

variable "azurerm_windows_function_app_website_content_share" {
  type        = string
  description = "The name of the Azure Storage file share used by the function app."
}

variable "azurerm_app_service_virtual_network_integration_subnet_id" {
  type        = string
  description = "The ID for the virtual network subnet used for virtual network integration."
}

variable "azurerm_function_app_app_settings" {
  type        = map(string)
  description = "Collection of additional application settings used by the function app."
}

variable "azurerm_windows_function_app_storage_key_vault_id" {
  type        = string
  description = "Id for the Key Vault secret containing the Azure Storage connection string to be used by the Azure Function."
}

variable "azurerm_windows_function_app_identity_id" {
  type        = string
  description = "Id for the managed identity used by the Azure Function."
}
