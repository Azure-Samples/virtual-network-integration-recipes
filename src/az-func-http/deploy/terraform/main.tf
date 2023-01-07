# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.25.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }

  required_version = "1.3.2"
}

provider "azurerm" {
  features {}
}

provider "http" {
  # Configuration options
}

provider "random" {
  # Configuration options
}

locals {
  azurerm_function_app_name = "func-${local.base_name}"
  resource_group_name       = azurerm_resource_group.rg.name

  base_name                     = length(var.resourceBaseName) != 0 ? var.resourceBaseName : random_string.base_name.result
  dns_function_app_private_link = "privatelink.azurewebsites.net"
}

data "azurerm_client_config" "current" {}

// TODO: REMOVE
data "http" "myip" {
  url = "https://ipv4.icanhazip.com/"
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

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_user_assigned_identity" "funcid" {
  name                = "id-${local.base_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# data "azurerm_resource_group" "ops_rg" {
#   name = var.dns_zone_resource_group_name
# }

module "vnet" {
  source              = "../../../common/infrastructure/terraform/modules/virtual-network/"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  azurerm_virtual_network_address_space = var.vnet_address_prefix
  azurerm_virtual_network_name          = "vnet-${local.base_name}"

  azurerm_subnet_app_service_integration_address_prefixes  = var.vnet_subnet_app_service_integration_address_prefixes
  azurerm_subnet_private_endpoints_address_prefixes        = var.vnet_subnet_private_endpoints_address_prefixes
  azurerm_subnet_app_service_integration_subnet_name       = "snet-${local.base_name}-appServiceInt"
  azurerm_subnet_private_endpoints_name                    = "snet-${local.base_name}-privateEndpoints"
  azurerm_subnet_app_service_integration_service_endpoints = []

  azurerm_network_security_group_name = "nsg-${local.base_name}"
}

module "app-insights" {
  source              = "../../../common/infrastructure/terraform/modules/application-insights"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  azurerm_application_insights_name    = "appi-${local.base_name}"
  azurerm_log_analytics_workspace_name = "log-${local.base_name}"
}

module "private-storage-account" {
  source              = "../../../common/infrastructure/terraform/modules/private-storage-account/"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  azurerm_storage_account_name = "st${local.base_name}"

  azurerm_private_dns_zone_virtual_network_id = module.vnet.network_details.vnet_id

  azurerm_private_endpoint_storage_blob_name                     = "pe-${local.base_name}-stb"
  azurerm_private_endpoint_storage_file_name                     = "pe-${local.base_name}-stf"
  azurerm_private_endpoint_storage_queue_name                    = "pe-${local.base_name}-stq"
  azurerm_private_endpoint_storage_table_name                    = "pe-${local.base_name}-stt"
  azurerm_private_endpoint_storage_endpoint_subnet_id            = module.vnet.network_details.private_endpoint_subnet_id
  azurerm_private_endpoint_storage_table_service_connection_name = "st-table-private-service-connection"
  azurerm_private_endpoint_storage_file_service_connection_name  = "st-file-private-service_connection"
  azurerm_private_endpoint_storage_queue_service_connection_name = "st-queue-private-service-connection"
  azurerm_private_endpoint_storage_blob_service_connection_name  = "st-blob-private-service-connection"

  dns_zone_resource_group_name = var.newOrExistingDnsZones == "new" ? local.resource_group_name : var.dns_zone_resource_group_name
  newOrExistingDnsZones        = var.newOrExistingDnsZones
}

module "function-app" {
  source              = "../../../common/infrastructure/terraform/modules/azure-linux-function"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  azurerm_service_plan_name                                 = "plan-${local.base_name}"
  azurerm_app_service_virtual_network_integration_subnet_id = module.vnet.network_details.app_service_integration_subnet_id

  azurerm_linux_function_app_name                                   = local.azurerm_function_app_name
  azurerm_linux_function_app_storage_account_name                   = module.private-storage-account.storage_account_details.name
  azurerm_linux_function_app_website_content_share                  = var.azurerm_storage_share_name
  azurerm_linux_function_app_application_insights_connection_string = module.app-insights.azurerm_application_insights_connection_string
  azurerm_linux_function_app_storage_key_vault_id                   = azurerm_key_vault_secret.storage-connection-string.id
  azurerm_linux_function_app_identity_id                            = azurerm_user_assigned_identity.funcid.id
}

module "private-key-vault" {
  source              = "../../../common/infrastructure/terraform/modules/private-key-vault"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags
  key_vault_name      = "kv-${local.base_name}"

  azurerm_private_endpoint_kv_private_endpoint_name                    = "pe-${local.base_name}-kv"
  azurerm_private_endpoint_kv_private_endpoint_subnet_id               = module.vnet.network_details.private_endpoint_subnet_id
  azurerm_private_endpoint_kv_private_endpoint_service_connection_name = "kv-private-service-connection"
  azurerm_private_dns_zone_virtual_network_id                          = module.vnet.network_details.vnet_id

  dns_zone_resource_group_name = var.newOrExistingDnsZones == "new" ? local.resource_group_name : var.dns_zone_resource_group_name
  newOrExistingDnsZones        = var.newOrExistingDnsZones
}

resource "azurerm_storage_account_network_rules" "st-network-rules" {
  storage_account_id = module.private-storage-account.storage_account_details.id

  default_action = "Deny"

  bypass = ["None"]

  ip_rules = [data.http.myip.response_body] // TODO: REMOVE

  depends_on = [
    module.private-storage-account,
    module.function-app
  ]
}

resource "azurerm_key_vault_access_policy" "kv-func-access-policy" {
  key_vault_id = module.private-key-vault.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.funcid.principal_id

  secret_permissions = [
    "Get"
  ]
}

data "azurerm_private_dns_zone" "sites-private-link" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_function_app_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "sites-private-link" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_function_app_private_link
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sites-private-link" {
  name                  = "${local.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? local.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.sites-private-link[0].name : data.azurerm_private_dns_zone.sites-private-link[0].name
  virtual_network_id    = module.vnet.network_details.vnet_id
}

resource "azurerm_private_endpoint" "sites-private-endpoint" {
  name                = "pe-${local.base_name}-sites"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  subnet_id = module.vnet.network_details.private_endpoint_subnet_id

  private_service_connection {
    name                           = "azurewebsites-private-service-connection"
    private_connection_resource_id = module.function-app.azure_function_id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sites-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.sites-private-link[0].id] : [data.azurerm_private_dns_zone.sites-private-link[0].id]
  }
}

resource "azurerm_key_vault_secret" "appi-instrumentation-key" {
  name         = "kvs-${local.base_name}-aikey"
  value        = module.app-insights.instrumentation_key
  key_vault_id = module.private-key-vault.key_vault_id
}

resource "azurerm_key_vault_secret" "storage-connection-string" {
  name         = "kvs-${local.base_name}-stconn"
  value        = module.private-storage-account.storage_account_details.primary_connection_string
  key_vault_id = module.private-key-vault.key_vault_id
}
