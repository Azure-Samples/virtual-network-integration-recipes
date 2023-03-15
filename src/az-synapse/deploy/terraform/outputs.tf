output "vnet_name" {
  value = module.vnet.virtual_network_name
}

output "private_endpoint_subnet_name" {
  value = module.vnet.private_endpoint_subnet_name
}

output "keyvault_name" {
  value = module.key-vault.key_vault_name
}

output "synapse_workspace_name" {
  value = module.synapse.synapse_workspace_name
}

output "synapse_default_storage_account_name" {
  value = module.storage.synapse_storage_account_name
}

output "main_storage_account_name" {
  value = module.storage.main_storage_account_name
}

output "synapse_sql_pool_name" {
  value = module.synapse.synapse_sql_pool_name
}

output "synapse_bigdata_pool_name" {
  value = module.synapse.synapse_big_data_pool_name
}
