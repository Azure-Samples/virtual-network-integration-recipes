resource "azurerm_service_plan" "linux_plan" {
  name                = var.azurerm_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  sku_name            = "EP1"
  os_type             = "Linux"
}

resource "azurerm_linux_function_app" "linux_func" {
  name                = var.azurerm_linux_function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  service_plan_id                 = azurerm_service_plan.linux_plan.id
  storage_key_vault_secret_id     = var.azurerm_linux_function_app_storage_key_vault_id
  key_vault_reference_identity_id = var.azurerm_linux_function_app_identity_id
  functions_extension_version     = "~3"
  builtin_logging_enabled         = false

  // Could not get a SystemAssigned identity to work correctly when using 
  // Key Vault references. Unable to figure out how to get Key Vault access
  // policy set to enable function app to get secrets (chicken/egg scenario?).
  // Setting a user assigned managed identity works, but differs from Bicep
  // version of this recipe.
  identity {
    type         = "UserAssigned"
    identity_ids = [var.azurerm_linux_function_app_identity_id]
  }

  site_config {
    runtime_scale_monitoring_enabled = true
    vnet_route_all_enabled           = true
    ftps_state                       = "Disabled"

    application_insights_connection_string = var.azurerm_linux_function_app_application_insights_connection_string

    application_stack {
      python_version = "3.8"
    }
  }

  app_settings = merge(var.azurerm_function_app_app_settings, {
    WEBSITE_CONTENTOVERVNET              = 1
    WEBSITE_CONTENTSHARE                 = azurerm_storage_share.fn-content-share.name
    WEBSITE_SKIP_CONTENTSHARE_VALIDATION = 1
  })
}

resource "azurerm_app_service_virtual_network_swift_connection" "fn-vnet-swift" {
  app_service_id = azurerm_linux_function_app.linux_func.id
  subnet_id      = var.azurerm_app_service_virtual_network_swift_connection_subnet_id
}

resource "azurerm_storage_share" "fn-content-share" {
  name                 = var.azurerm_linux_function_app_website_content_share
  storage_account_name = var.azurerm_linux_function_app_storage_account_name
  quota                = 5120
}

