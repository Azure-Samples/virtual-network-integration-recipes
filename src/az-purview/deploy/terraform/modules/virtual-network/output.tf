output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "private_endpoint_subnet_name" {
  value = azurerm_subnet.private_endpoint.name
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoint.id
}
