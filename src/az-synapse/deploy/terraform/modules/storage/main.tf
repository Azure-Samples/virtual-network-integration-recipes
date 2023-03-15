terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.spoke]
    }
  }
}

locals {
  dns_storage_private_links_all_accounts = flatten([
    for k, v in var.storage_account_names : [
      for link_name, link_value in var.private_dns_names : {
        unique_id              = "${link_name}${k}"
        storage_account_name   = v
        dns_name               = link_value
        subresource_names      = link_name
        storage_account_ref_id = k
      }
    ]
  ])
}

resource "azurerm_storage_account" "storage" {
  for_each            = var.storage_account_names
  name                = each.value
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  provider            = azurerm.spoke

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "RAGRS"
  is_hns_enabled            = "true"
  access_tier               = "Hot"
  enable_https_traffic_only = "true"
}

# resource "azurerm_storage_data_lake_gen2_filesystem" "container" {
#   for_each           = var.storage_account_names
#   name               = var.default_container_name
#   storage_account_id = azurerm_storage_account.storage[each.key].id
#   provider           = azurerm.spoke
# }

resource "azurerm_resource_group_template_deployment" "storage-containers" {
  for_each            = var.storage_account_names
  name                = "${each.value}-container"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  depends_on = [
    azurerm_storage_account.storage
  ]

  parameters_content = jsonencode({
    "location"             = { value = var.location }
    "storageAccountName"   = { value = azurerm_storage_account.storage[each.key].name }
    "defaultContainerName" = { value = var.default_container_name }
  })

  template_content = file("${path.module}/storage-container.json")
}

resource "azurerm_private_endpoint" "st_privatelinks" {
  for_each = {
    for dns in local.dns_storage_private_links_all_accounts : dns.unique_id => dns
  }
  name                = "pe-st-${each.key}-${var.base_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  subnet_id           = var.private_endpoint_subnet_id
  provider            = azurerm.spoke

  private_service_connection {
    name                           = "plsc-st-${each.key}-${var.base_name}"
    private_connection_resource_id = azurerm_storage_account.storage[each.value.storage_account_ref_id].id
    is_manual_connection           = false
    subresource_names              = [each.value.subresource_names]
  }

  private_dns_zone_group {
    name                 = "${each.key}-private-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids[each.value.subresource_names]]
  }
}

resource "azurerm_storage_account_network_rules" "st_rules" {
  for_each           = var.storage_account_names
  storage_account_id = azurerm_storage_account.storage[each.key].id
  default_action     = "Deny"
  bypass             = ["None"]
  provider           = azurerm.spoke

  depends_on = [
    azurerm_private_endpoint.st_privatelinks
  ]
}
