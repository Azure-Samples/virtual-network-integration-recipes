output "azure_app_service_id" {
  value = azurerm_windows_web_app.webapp.id
}

output "azure_app_service_default_site_hostname" {
  value = azurerm_windows_web_app.webapp.default_hostname
}

output "azure_app_service_tenant_id" {
  value     = azurerm_windows_web_app.webapp.identity[0].tenant_id
  sensitive = true
}

output "azure_app_service_principal_id" {
  value     = azurerm_windows_web_app.webapp.identity[0].principal_id
  sensitive = true
}

output "azure_app_service_plan_name" {
  value = azurerm_service_plan.plan.name
}
