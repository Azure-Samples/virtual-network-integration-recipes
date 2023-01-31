terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "3.41.0"
      configuration_aliases = [azurerm.spoke]
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  tags                = var.tags
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_prefix]
}

resource "azurerm_subnet" "azure-bastion-integration" {
  name                 = var.azure_bastion_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.bastion_subnet_address_prefix]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = var.private_endpoint_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.private_endpoint_subnet_address_prefix]
  private_endpoint_network_policies_enabled = true
}
