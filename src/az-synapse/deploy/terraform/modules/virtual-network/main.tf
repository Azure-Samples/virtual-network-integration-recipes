terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.spoke]
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  tags                = var.tags
  resource_group_name = var.resource_group_name
  address_space       = [var.virtual_network_address_prefix]
}

resource "azurerm_subnet" "azure_bastion_integration" {
  name                 = var.azure_bastion_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [var.bastion_subnet_address_prefix]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [var.private_endpoint_subnet_address_prefix]

  enforce_private_link_endpoint_network_policies = true
}
