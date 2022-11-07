resource "azurerm_network_security_group" "private_endpoint_nsg" {
  name                = "${var.azurerm_network_security_group_name}-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule = []
}

resource "azurerm_network_security_group" "app_service_integration_nsg" {
  name                = "${var.azurerm_network_security_group_name}-appServiceInt"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule = []
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.azurerm_virtual_network_name
  location            = var.location
  tags                = var.tags
  resource_group_name = var.resource_group_name
  address_space       = [var.azurerm_virtual_network_address_space]
}

resource "azurerm_subnet" "app-service-integration" {
  name                 = var.azurerm_subnet_app_service_integration_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.azurerm_virtual_network_name
  address_prefixes     = [var.azurerm_subnet_app_service_integration_address_prefixes]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
  service_endpoints = var.azurerm_subnet_app_service_integration_service_endpoints

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "private-endpoints" {
  name                                      = var.azurerm_subnet_private_endpoints_name
  resource_group_name                       = var.resource_group_name
  virtual_network_name                      = var.azurerm_virtual_network_name
  address_prefixes                          = [var.azurerm_subnet_private_endpoints_address_prefixes]
  private_endpoint_network_policies_enabled = true

  depends_on = [
    azurerm_virtual_network.vnet
  ]

}

resource "azurerm_subnet_network_security_group_association" "nsg-private-endpoints" {
  subnet_id                 = azurerm_subnet.private-endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoint_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg-app-service-integration" {
  subnet_id                 = azurerm_subnet.app-service-integration.id
  network_security_group_id = azurerm_network_security_group.app_service_integration_nsg.id
}

