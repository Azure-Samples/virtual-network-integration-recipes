locals {
  // Generating unique name to be added to the resource names
  base_name           = random_string.base_name.result
  pe_base_name_suffix = local.base_name

  purview_account_name = "pview-${local.base_name}"

  // Private DNS Zones Map
  private_dns_names_map = {
    "ServiceBus"    = "privatelink.servicebus.windows.net"
    "PurviewStudio" = "privatelink.purviewstudio.azure.com"
    "Purview"       = "privatelink.purview.azure.com"
    "Vault"         = "privatelink.vaultcore.azure.net"
    "Blob"          = "privatelink.blob.core.windows.net"
    "Dfs"           = "privatelink.dfs.core.windows.net"
    "Queue"         = "privatelink.queue.core.windows.net"
  }

  purview_private_dns_zone_id_map = {
    "namespace" = {
      "dns_zone_id" = module.dns.purview_private_dns_zone_id
    }

    "portal" = {
      "dns_zone_id" = module.dns.purview_private_dns_zone_id
    }

    "account" = {
      "dns_zone_id" = module.dns.purview_studio_private_dns_zone_id
    }

    "blob" = {
      "dns_zone_id" = module.dns.blob_private_dns_zone_id
    }

    "queue" = {
      "dns_zone_id" = module.dns.queue_private_dns_zone_id
    }
  }

  // VNet variables
  virtual_network_name         = "vnet-${local.base_name}"
  private_endpoint_subnet_name = "snet-${local.base_name}-pe"
  azure_bastion_subnet_name    = "AzureBastionSubnet"

  // Azure Storage variables
  storage_account_name   = "st${local.base_name}"
  default_container_name = "container001"
  private_dns_names_map_for_storage = {
    "blob" = "privatelink.blob.core.windows.net"
    "dfs"  = "privatelink.dfs.core.windows.net"
  }

  // Azure Key Vault variables
  key_vault_name     = "kv-${local.base_name}"
  keyvault_sku_name  = "standard"
  azurerm_pe_kv_name = "pe-kv-vault-${local.base_name}"
}
