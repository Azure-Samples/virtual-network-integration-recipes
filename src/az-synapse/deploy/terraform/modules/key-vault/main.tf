terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.spoke]
    }
  }
}

resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  tenant_id           = var.azure_tenant_id
  sku_name            = "standard"
  provider            = azurerm.spoke

  network_acls {
    bypass         = "None"
    default_action = "Deny"
  }

  lifecycle {
    ignore_changes = [
      access_policy
    ]
  }
}

resource "azurerm_private_endpoint" "kv-private-endpoint" {
  name                = var.key_vault_private_endpoint_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  subnet_id           = var.private_endpoint_subnet_id
  provider            = azurerm.spoke

  private_service_connection {
    name                           = "plsc-kv-vault-${var.base_name}"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyvault-private-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_key_vault_access_policy" "kv-access-policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.synapse_workspace_tenant_id
  object_id    = var.synapse_workspace_principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [
    azurerm_private_endpoint.kv-private-endpoint
  ]
}
