terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_virtual_network_peering" "vnet-peering" {
  name                      = "peer-${var.virtual_network_name}-${var.remote_virtual_network_name}"
  virtual_network_name      = var.virtual_network_name
  resource_group_name       = var.resource_group_name
  remote_virtual_network_id = var.remote_virtual_network_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}
