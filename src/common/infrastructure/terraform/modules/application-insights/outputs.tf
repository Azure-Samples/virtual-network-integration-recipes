output "instrumentation_key" {
  sensitive = true
  value     = azurerm_application_insights.appi.instrumentation_key
}

output "azurerm_application_insights_id" {
  value = azurerm_application_insights.appi.id
}

output "azurerm_log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics_workspace.id
}

output "azurerm_application_insights_connection_string" {
  sensitive = true
  value     = azurerm_application_insights.appi.connection_string
}
