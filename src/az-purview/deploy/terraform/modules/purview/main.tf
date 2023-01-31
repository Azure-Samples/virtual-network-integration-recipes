terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "3.41.0"
      configuration_aliases = [azurerm.spoke]
    }
  }
}

resource "azurerm_purview_account" "purview" {
  name                = var.purview_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  provider            = azurerm.spoke

  managed_resource_group_name = "${var.resource_group_name}-managed"
  public_network_enabled      = false

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

locals {
  purview_dns_private_endpoint_names = [
    "namespace",
    "portal",
    "account",
    "blob",
    "queue",
  ]
}

resource "azurerm_private_endpoint" "purview_privatelinks" {
  for_each            = toset(local.purview_dns_private_endpoint_names)
  name                = "pe-pview-${each.key}-${var.pe_base_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  provider            = azurerm.spoke

  subnet_id = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "plsc-pview-${each.key}-${var.pe_base_name}"
    private_connection_resource_id = ("${each.key}" == "namespace") ? azurerm_purview_account.purview.managed_resources[0].event_hub_namespace_id : ("${each.key}" == "blob" || "${each.key}" == "queue") ? azurerm_purview_account.purview.managed_resources[0].storage_account_id : azurerm_purview_account.purview.id
    is_manual_connection           = false
    subresource_names              = ["${each.key}"]
  }

  private_dns_zone_group {
    name                 = "pdzg-pview-${each.key}-${var.pe_base_name}"
    private_dns_zone_ids = [var.purview_private_dns_zone_id_map[each.key].dns_zone_id]
  }
}
