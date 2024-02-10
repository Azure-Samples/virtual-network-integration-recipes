output "synapse_workspace_name" {
  value = azurerm_synapse_workspace.syn-ws.name
}

output "synapse_sql_pool_name" {
  value = azurerm_synapse_sql_pool.syn-sql-pool.name
}

output "synapse_big_data_pool_name" {
  value = azurerm_synapse_spark_pool.syn-spark-pool.name
}

output "synapse_workspace_principal_id" {
  value = azurerm_synapse_workspace.syn-ws.identity[0].principal_id
}

output "synapse_workspace_tenant_id" {
  value = azurerm_synapse_workspace.syn-ws.identity[0].tenant_id
}
