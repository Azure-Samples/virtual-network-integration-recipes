# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.41.0"
    }
  }

  required_version = "1.3.2"
}

// Current Subscription
data "azurerm_subscription" "default" {}

// Subscription for existing Private DNS Zones, ignore if "new_or_existing_dns_zones" variable is set to "new"
data "azurerm_subscription" "ops_subscription" {
  count           = var.new_or_existing_dns_zones == "new" ? 0 : 1
  subscription_id = var.dns_zone_resource_group_subscription_id
}

// Default provider
provider "azurerm" {
  features {}
}

// Provider for the recipe
provider "azurerm" {
  features {}
  alias           = "spoke"
  subscription_id = data.azurerm_subscription.default.subscription_id
}

// Provider for the Private DNS Zones' subscription
// - If "new_or_existing_dns_zones" variable is set to "new", use the current subscription id
// - Otherwise, use the existing DNS Zone's subscription id (variable "dns_zone_resource_group_subscription_id")
provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.new_or_existing_dns_zones == "new" ? data.azurerm_subscription.default.subscription_id : data.azurerm_subscription.ops_subscription[0].subscription_id
}

// Resouce group to deploy the recipe
resource "azurerm_resource_group" "spoke" {
  name     = var.resource_group_name
  location = var.location
  provider = azurerm.spoke
}

// Resource group of existing Private DNS Zones, ignore if "new_or_existing_dns_zones" variable is set to "new"
data "azurerm_resource_group" "hub" {
  count    = var.new_or_existing_dns_zones == "new" ? 0 : 1
  name     = var.dns_zone_resource_group_name
  provider = azurerm.hub
}

locals {
  calc_sub_for_private_dns_zone = var.new_or_existing_dns_zones == "new" ? data.azurerm_subscription.default.subscription_id : data.azurerm_subscription.ops_subscription[0].subscription_id
  calc_rg_for_private_dns_zone  = var.new_or_existing_dns_zones == "new" ? azurerm_resource_group.spoke.name : data.azurerm_resource_group.hub[0].name
}

resource "random_string" "base_name" {
  length  = 6
  special = false
  numeric = true
  upper   = false
  keepers = {
    resource_group = azurerm_resource_group.spoke.name
  }
}

module "dns" {
  source              = "./modules/private-dns-zones"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = var.tags

  private_dns_names_map                   = local.private_dns_names_map
  new_or_existing_dns_zones               = var.new_or_existing_dns_zones
  dns_zone_resource_group_name            = local.calc_rg_for_private_dns_zone
  dns_zone_resource_group_subscription_id = local.calc_sub_for_private_dns_zone

  providers = {
    azurerm.spoke = azurerm.spoke
    azurerm.hub   = azurerm.hub
  }
}

module "vnet" {
  source              = "./modules/virtual-network"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = var.tags

  virtual_network_name                   = local.virtual_network_name
  private_endpoint_subnet_name           = local.private_endpoint_subnet_name
  azure_bastion_subnet_name              = local.azure_bastion_subnet_name
  vnet_address_prefix                    = var.vnet_address_prefix
  private_endpoint_subnet_address_prefix = var.private_endpoint_subnet_address_prefix
  bastion_subnet_address_prefix          = var.bastion_subnet_address_prefix

  providers = {
    azurerm.spoke = azurerm.spoke
  }
}

module "purview" {
  source                          = "./modules/purview"
  resource_group_name             = azurerm_resource_group.spoke.name
  location                        = var.location
  tags                            = var.tags
  purview_account_name            = local.purview_account_name
  purview_private_dns_zone_id_map = local.purview_private_dns_zone_id_map
  private_endpoint_subnet_id      = module.vnet.private_endpoint_subnet_id
  pe_base_name                    = local.pe_base_name_suffix

  providers = {
    azurerm.spoke = azurerm.spoke
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "private-dns-zone-vnet-links" {
  for_each              = local.private_dns_names_map
  name                  = "${local.calc_rg_for_private_dns_zone}-${each.key}-link"
  resource_group_name   = local.calc_rg_for_private_dns_zone
  private_dns_zone_name = each.value
  provider              = azurerm.spoke
  virtual_network_id    = module.vnet.vnet_id
}

module "storage" {
  source                 = "./modules/storage"
  resource_group_name    = azurerm_resource_group.spoke.name
  location               = var.location
  tags                   = var.tags
  storage_account_name   = local.storage_account_name
  default_container_name = local.default_container_name

  private_dns_zone_ids = {
    "blob" = module.dns.blob_private_dns_zone_id
    "dfs"  = module.dns.dfs_private_dns_zone_id
  }

  pe_subnet_id                      = module.vnet.private_endpoint_subnet_id
  pe_base_name                      = local.pe_base_name_suffix
  private_dns_names_map_for_storage = local.private_dns_names_map_for_storage

  providers = {
    azurerm.spoke = azurerm.spoke
  }
}

module "keyvault" {
  source                       = "./modules/keyvault"
  resource_group_name          = azurerm_resource_group.spoke.name
  location                     = var.location
  tags                         = var.tags
  key_vault_name               = local.key_vault_name
  keyvault_sku_name            = local.keyvault_sku_name
  azurerm_purview_tenant_id    = module.purview.purview_tenant_id
  azurerm_purview_principal_id = module.purview.purview_principal_id
  private_dns_zone_id          = module.dns.vault_private_dns_zone_id
  pe_subnet_id                 = module.vnet.private_endpoint_subnet_id
  azurerm_pe_kv_name           = local.azurerm_pe_kv_name

  providers = {
    azurerm.spoke = azurerm.spoke
  }
}
