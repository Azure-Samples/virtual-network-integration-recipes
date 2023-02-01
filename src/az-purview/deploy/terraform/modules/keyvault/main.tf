terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "3.41.0"
      configuration_aliases = [azurerm.spoke]
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                          = var.key_vault_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tags                          = var.tags
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.keyvault_sku_name
  provider                      = azurerm.spoke
  public_network_access_enabled = false

  access_policy {
    tenant_id = var.azurerm_purview_tenant_id
    object_id = var.azurerm_purview_principal_id
    secret_permissions = [
      "Get",
      "List"
    ]
  }

  network_acls {
    bypass         = "None"
    default_action = "Deny"
  }

  lifecycle {
    ignore_changes = [
      access_policy,
      tags
    ]
  }
}

resource "azurerm_private_endpoint" "private_endpoint_keyvault" {
  name                = var.azurerm_pe_kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = var.azurerm_pe_kv_service_connection_name
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "keyvault-private-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
