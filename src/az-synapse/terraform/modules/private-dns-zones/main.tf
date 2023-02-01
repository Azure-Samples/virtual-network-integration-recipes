terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.hub, azurerm.spoke]
    }
  }
}

// Get reference to existing Private DNS zones if integrating with Hub, ignore otherwise
resource "azurerm_private_dns_zone" "dns_zones" {
  for_each            = var.integrate_with_hub ? {} : var.private_dns_names_map
  name                = each.value
  resource_group_name = var.resource_group_name
  provider            = azurerm.spoke
  tags                = var.tags
}

// Get reference to existing Private DNS zones if integrating with Hub, ignore otherwise
data "azurerm_private_dns_zone" "ops_dns_zones" {
  for_each            = var.integrate_with_hub ? var.private_dns_names_map : {}
  name                = each.value
  resource_group_name = var.dns_zone_resource_group_name
  provider            = azurerm.hub
}

// Now that we have the required references for Private DNS Zone (existing or new), get the IDs which can be used while creating the private endpoints
locals {
  sql_private_dns_zone_id   = var.integrate_with_hub ? data.azurerm_private_dns_zone.ops_dns_zones["Sql"].id : azurerm_private_dns_zone.dns_zones["Sql"].id
  dev_private_dns_zone_id   = var.integrate_with_hub ? data.azurerm_private_dns_zone.ops_dns_zones["Dev"].id : azurerm_private_dns_zone.dns_zones["Dev"].id
  web_private_dns_zone_id   = var.integrate_with_hub ? data.azurerm_private_dns_zone.ops_dns_zones["Web"].id : azurerm_private_dns_zone.dns_zones["Web"].id
  dfs_private_dns_zone_id   = var.integrate_with_hub ? data.azurerm_private_dns_zone.ops_dns_zones["dfs"].id : azurerm_private_dns_zone.dns_zones["dfs"].id
  blob_private_dns_zone_id  = var.integrate_with_hub ? data.azurerm_private_dns_zone.ops_dns_zones["blob"].id : azurerm_private_dns_zone.dns_zones["blob"].id
  vault_private_dns_zone_id = var.integrate_with_hub ? data.azurerm_private_dns_zone.ops_dns_zones["vault"].id : azurerm_private_dns_zone.dns_zones["vault"].id
}
