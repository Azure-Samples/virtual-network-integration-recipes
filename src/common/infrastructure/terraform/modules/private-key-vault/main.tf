data "azurerm_client_config" "current" {}

locals {
  dns_key_vault_private_link = "privatelink.vaultcore.azure.net"
}

resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "Purge"
    ]
    certificate_permissions = [
      "Get",
      "Import",
      "Delete",
      "Purge"
    ]
  }

  network_acls {
    bypass         = "None"
    default_action = "Allow"
    // NOTE: Terraform does not allow for Key Vault network ACL to be set independently of Key Vault
    //       resource creation. As such, after the Key Vault resource is created, when network ACLs are set for
    //       "Bypass = None" and "Default_Action = Deny", Key Vault
    //       secrets cannot be set via Terraform.
    //       
    //       Please see discussion at https://github.com/terraform-providers/terraform-provider-azurerm/issues/3130
  }

  lifecycle {
    ignore_changes = [
      access_policy
    ]
  }
}

data "azurerm_private_dns_zone" "kv-private-link" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_key_vault_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "kv-private-link" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_key_vault_private_link
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv-private-link" {
  name                  = "${var.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? var.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.kv-private-link[0].name : data.azurerm_private_dns_zone.kv-private-link[0].name
  virtual_network_id    = var.azurerm_private_dns_zone_virtual_network_id
}

resource "azurerm_private_endpoint" "kv-private-endpoint" {
  name                = var.azurerm_private_endpoint_kv_private_endpoint_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  subnet_id           = var.azurerm_private_endpoint_kv_private_endpoint_subnet_id

  private_service_connection {
    name                           = var.azurerm_private_endpoint_kv_private_endpoint_service_connection_name
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyvault-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.kv-private-link[0].id] : [data.azurerm_private_dns_zone.kv-private-link[0].id]
  }
}
