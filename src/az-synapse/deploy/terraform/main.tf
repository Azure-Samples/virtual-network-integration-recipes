# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.15.1"
    }
  }

  required_version = ">=1.2.6"
}

// Current Subscription
data "azurerm_subscription" "default" {}

// Current client configuration
data "azurerm_client_config" "current" {}

// Subscription for existing Private DNS Zones if integrating with existing Hub ("integrate_with_hub" set to true).
data "azurerm_subscription" "ops_subscription" {
  count           = var.integrate_with_hub ? 1 : 0
  subscription_id = var.hub_subscription_id
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
// - If "integrate_with_hub" variable is false, use the current subscription id
// - Otherwise, use the existing DNS Zone's subscription id (variable "hub_subscription_id")
provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.integrate_with_hub ? data.azurerm_subscription.ops_subscription[0].subscription_id : data.azurerm_subscription.default.subscription_id
}

// Resouce group to deploy the recipe
resource "azurerm_resource_group" "spoke" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags

  provider = azurerm.spoke
}

// Resource group of existing Private DNS Zones if integrating with existing Hub.
data "azurerm_resource_group" "hub" {
  count = var.integrate_with_hub ? 1 : 0
  name  = var.hub_resource_group_name

  provider = azurerm.hub
}

locals {
  calc_sub_for_private_dns_zone = var.integrate_with_hub ? data.azurerm_subscription.ops_subscription[0].subscription_id : data.azurerm_subscription.default.subscription_id
  calc_rg_for_private_dns_zone  = var.integrate_with_hub ? data.azurerm_resource_group.hub[0].name : azurerm_resource_group.spoke.name
}

resource "random_string" "base_name" {
  length  = 13
  special = false
  numeric = true
  upper   = false
  keepers = {
    resource_group = var.resource_group_name
  }
}

module "dns" {
  source              = "./modules/private-dns-zones"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.tags

  private_dns_names_map                   = local.private_dns_names_map
  integrate_with_hub                      = var.integrate_with_hub
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
  tags                = local.tags

  virtual_network_name                   = local.virtual_network_name
  private_endpoint_subnet_name           = local.private_endpoint_subnet_name
  azure_bastion_subnet_name              = local.azure_bastion_subnet_name
  virtual_network_address_prefix         = var.virtual_network_address_prefix
  private_endpoint_subnet_address_prefix = var.private_endpoint_subnet_address_prefix
  bastion_subnet_address_prefix          = var.bastion_subnet_address_prefix

  providers = {
    azurerm.spoke = azurerm.spoke
  }
}

data "azurerm_virtual_network" "hub-vnet" {
  count               = var.integrate_with_hub ? 1 : 0
  name                = var.hub_virtual_network_name
  resource_group_name = var.hub_resource_group_name
  provider            = azurerm.hub
}

// Peering to remote virtual network
module "peering" {
  count                       = var.integrate_with_hub ? 1 : 0
  source                      = "./modules/vnet-peering"
  virtual_network_name        = module.vnet.virtual_network_name
  resource_group_name         = azurerm_resource_group.spoke.name
  remote_virtual_network_name = data.azurerm_virtual_network.hub-vnet[0].name
  remote_virtual_network_id   = data.azurerm_virtual_network.hub-vnet[0].id

  providers = {
    azurerm = azurerm.spoke
  }
}

// Peering from remote virtual network
module "remote-peering" {
  count                       = var.integrate_with_hub ? 1 : 0
  source                      = "./modules/vnet-peering"
  virtual_network_name        = data.azurerm_virtual_network.hub-vnet[0].name
  resource_group_name         = data.azurerm_virtual_network.hub-vnet[0].resource_group_name
  remote_virtual_network_name = module.vnet.virtual_network_name
  remote_virtual_network_id   = module.vnet.virtual_network_id

  providers = {
    azurerm = azurerm.hub
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "private-dns-zone-vnet-links" {
  for_each              = local.private_dns_names_map
  name                  = "${module.vnet.virtual_network_name}-link"
  resource_group_name   = local.calc_rg_for_private_dns_zone
  private_dns_zone_name = each.value
  virtual_network_id    = module.vnet.virtual_network_id
  tags                  = local.tags

  provider = azurerm.hub
}

module "storage" {
  source              = "./modules/storage"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.tags
  base_name           = local.base_name

  storage_account_names      = local.storage_account_names
  default_container_name     = local.default_container_name
  private_dns_names          = local.private_dns_names_map_for_storage
  private_endpoint_subnet_id = module.vnet.private_endpoint_subnet_id

  private_dns_zone_ids = {
    "blob" = module.dns.blob_private_dns_zone_id
    "dfs"  = module.dns.dfs_private_dns_zone_id
  }
  providers = {
    azurerm.spoke = azurerm.spoke
  }

  depends_on = [
    module.peering,
    module.remote-peering,
    azurerm_private_dns_zone_virtual_network_link.private-dns-zone-vnet-links
  ]
}

locals {
  synapse_storage_file_system_id = "https://${module.storage.synapse_storage_account_name}.dfs.core.windows.net/${local.default_container_name}"
}

module "synapse" {
  source              = "./modules/synapse"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.tags
  base_name           = local.base_name

  synapse_workspace_name                   = local.synapse_workspace_name
  synapse_managed_resource_group_name      = local.synapse_managed_resource_group_name
  synapse_private_link_hub_name            = local.synapse_private_link_hub_name
  synapse_spark_pool_name                  = local.synapse_spark_pool_name
  synapse_sql_pool_name                    = local.synapse_sql_pool_name
  synapse_private_dns_zone_map             = local.synapse_private_dns_zone_map
  synapse_sql_administrator_login          = var.synapse_sql_administrator_login
  synapse_sql_administrator_login_password = var.synapse_sql_administrator_login_password
  synapse_storage_account_id               = module.storage.synapse_storage_account_id
  synapse_storage_file_system_id           = local.synapse_storage_file_system_id
  main_storage_account_id                  = module.storage.main_storage_account_id
  private_endpoint_subnet_id               = module.vnet.private_endpoint_subnet_id

  private_dns_zone_ids = {
    "Sql"         = module.dns.sql_private_dns_zone_id
    "Dev"         = module.dns.dev_private_dns_zone_id
    "Web"         = module.dns.web_private_dns_zone_id
    "SqlOnDemand" = module.dns.sql_private_dns_zone_id
  }
  providers = {
    azurerm.spoke = azurerm.spoke
  }

  depends_on = [
    module.storage
  ]
}

module "key-vault" {
  source              = "./modules/key-vault"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  tags                = local.tags
  base_name           = local.base_name

  key_vault_name                  = local.key_vault_name
  key_vault_private_endpoint_name = local.key_vault_private_endpoint_name
  azure_tenant_id                 = data.azurerm_client_config.current.tenant_id
  synapse_workspace_tenant_id     = module.synapse.synapse_workspace_tenant_id
  synapse_workspace_principal_id  = module.synapse.synapse_workspace_principal_id
  private_dns_zone_id             = module.dns.vault_private_dns_zone_id
  private_endpoint_subnet_id      = module.vnet.private_endpoint_subnet_id

  providers = {
    azurerm.spoke = azurerm.spoke
  }

  depends_on = [
    module.synapse
  ]
}
