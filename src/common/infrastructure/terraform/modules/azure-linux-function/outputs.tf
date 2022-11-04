output "azure_function_id" {
  value = azurerm_linux_function_app.linux_func.id
}

output "azure_function_tenant_id" {
  value     = azurerm_linux_function_app.linux_func.identity[0].tenant_id
  sensitive = true
}

output "azure_function_principal_id" {
  value     = azurerm_linux_function_app.linux_func.identity[0].principal_id
  sensitive = true
}
