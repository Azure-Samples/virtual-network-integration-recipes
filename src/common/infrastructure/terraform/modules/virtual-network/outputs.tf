output "network_details" {
  description = "Details pertaining to the created virtual network."
  value = {
    vnet_id                           = azurerm_virtual_network.vnet.id
    app_service_integration_subnet_id = azurerm_subnet.app-service-integration.id
    private_endpoint_subnet_id        = azurerm_subnet.private-endpoints.id
    name                              = azurerm_virtual_network.vnet.name
  }
}
