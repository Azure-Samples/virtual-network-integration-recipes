output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.vnet.id
}

output "private_endpoint_subnet_name" {
  value = azurerm_subnet.private_endpoints.name
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}
