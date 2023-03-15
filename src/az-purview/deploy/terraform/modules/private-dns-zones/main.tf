terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "3.41.0"
      configuration_aliases = [azurerm.hub, azurerm.spoke]
    }
  }
}

// Get reference to existing Private DNS zones if variable "new_or_existing_dns_zones" is set to "existing", ignore otherwise
resource "azurerm_private_dns_zone" "dns_zones" {
  for_each            = var.new_or_existing_dns_zones == "new" ? var.private_dns_names_map : {}
  name                = each.value
  resource_group_name = var.resource_group_name
  provider            = azurerm.spoke
}

// Get reference to existing Private DNS zones if variable "new_or_existing_dns_zones" is set to "existing", ignore otherwise
data "azurerm_private_dns_zone" "ops_dns_zones" {
  for_each            = var.new_or_existing_dns_zones == "existing" ? var.private_dns_names_map : {}
  name                = each.value
  resource_group_name = var.dns_zone_resource_group_name
  provider            = azurerm.hub
}

// Now that we have the required references for Private DNS Zone (existing or new), get the IDs which can be used while creating the private endpoints
locals {
  service_bus_private_dns_zone_id    = var.new_or_existing_dns_zones == "new" ? azurerm_private_dns_zone.dns_zones["ServiceBus"].id : data.azurerm_private_dns_zone.ops_dns_zones["ServiceBus"].id
  purview_studio_private_dns_zone_id = var.new_or_existing_dns_zones == "new" ? azurerm_private_dns_zone.dns_zones["PurviewStudio"].id : data.azurerm_private_dns_zone.ops_dns_zones["PurviewStudio"].id
  purview_private_dns_zone_id        = var.new_or_existing_dns_zones == "new" ? azurerm_private_dns_zone.dns_zones["Purview"].id : data.azurerm_private_dns_zone.ops_dns_zones["Purview"].id
  vault_private_dns_zone_id          = var.new_or_existing_dns_zones == "new" ? azurerm_private_dns_zone.dns_zones["Vault"].id : data.azurerm_private_dns_zone.ops_dns_zones["Vault"].id
  blob_private_dns_zone_id           = var.new_or_existing_dns_zones == "new" ? azurerm_private_dns_zone.dns_zones["Blob"].id : data.azurerm_private_dns_zone.ops_dns_zones["Blob"].id
  dfs_private_dns_zone_id            = var.new_or_existing_dns_zones == "new" ? azurerm_private_dns_zone.dns_zones["Dfs"].id : data.azurerm_private_dns_zone.ops_dns_zones["Dfs"].id
  queue_private_dns_zone_id          = var.new_or_existing_dns_zones == "new" ? azurerm_private_dns_zone.dns_zones["Queue"].id : data.azurerm_private_dns_zone.ops_dns_zones["Queue"].id
}
