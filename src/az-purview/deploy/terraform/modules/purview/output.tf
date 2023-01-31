output "purview_principal_id" {
    value = azurerm_purview_account.purview.identity[0].principal_id
}

output "purview_tenant_id" {
    value = azurerm_purview_account.purview.identity[0].tenant_id
}
