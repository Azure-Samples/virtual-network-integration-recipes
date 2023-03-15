terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "3.41.0"
      configuration_aliases = [azurerm.spoke]
    }

    azapi = {
      source = "azure/azapi"
    }
  }
}

locals {
  dns_storage_private_links_all_accounts = flatten([
    for link_name, link_value in var.private_dns_names_map_for_storage : {
      unique_id         = "${link_name}-st"
      dns_name          = link_value
      subresource_names = link_name
    }
  ])
}

# Create the primary storage account.
resource "azurerm_storage_account" "st" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "RAGRS"
  is_hns_enabled            = true
  access_tier               = "Hot"
  enable_https_traffic_only = true

  public_network_access_enabled = false

  network_rules {
    bypass         = ["None"]
    default_action = "Deny"
  }
}

# Creating the container with the resource "azurerm_storage_container" does not work here
# because the storage account is blocked from outside access. Using the new provider
# azapi, built on top of the Azure ARM REST APIs solves it.
resource "azapi_resource" "st" {
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01"
  name      = var.default_container_name
  parent_id = "${azurerm_storage_account.st.id}/blobServices/default"
  body = jsonencode({
    properties = {
      publicAccess = "None"
    }
  })
}

resource "azurerm_role_assignment" "st" {
  scope                = azurerm_storage_account.st.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.azurerm_purview_principal_id
}

resource "azurerm_private_endpoint" "st_privatelinks" {
  for_each = {
    for dns in local.dns_storage_private_links_all_accounts : dns.unique_id => dns
  }
  name                = "pe-st-${each.key}-${var.pe_base_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  subnet_id           = var.pe_subnet_id
  provider            = azurerm.spoke

  private_service_connection {
    name                           = "plsc-st-${each.key}-${var.pe_base_name}"
    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false
    subresource_names              = [each.value.subresource_names]
  }

  private_dns_zone_group {
    name                 = "pdzg-st-${each.key}-${var.pe_base_name}"
    private_dns_zone_ids = [var.private_dns_zone_ids[each.value.subresource_names]]
  }
}
