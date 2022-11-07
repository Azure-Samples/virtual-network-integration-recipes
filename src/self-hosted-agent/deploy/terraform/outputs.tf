output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = module.self-hosted-agent.virtual_network_name
}
