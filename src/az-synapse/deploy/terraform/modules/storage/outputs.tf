output "synapse_storage_account_id" {
  value = azurerm_storage_account.storage[0].id
}

output "main_storage_account_id" {
  value = azurerm_storage_account.storage[1].id
}

output "synapse_storage_account_name" {
  value = azurerm_storage_account.storage[0].name
}

output "main_storage_account_name" {
  value = azurerm_storage_account.storage[1].name
}

output "synapse_storage_file_system_name" {
  value = var.default_container_name
}
output "main_storage_file_system_name" {
  value = var.default_container_name
}
