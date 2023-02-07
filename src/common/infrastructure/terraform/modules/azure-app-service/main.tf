resource "azurerm_service_plan" "plan" {
  name                = var.azurerm_app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  os_type             = "Windows"
  sku_name            = var.azurerm_app_service_plan_size
}

resource "azurerm_windows_web_app" "webapp" {
  name                = var.azurerm_app_service_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  service_plan_id = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    ftps_state = "Disabled"
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = var.azurerm_app_service_appinsights_instrumentation_key
  }

  virtual_network_subnet_id = var.azurerm_app_service_virtual_network_integration_subnet_id
}
