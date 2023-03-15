locals {
  // Generating unique name to be added to the resource names
  base_name = lower(length(var.resource_base_name) != 0 ? var.resource_base_name : random_string.base_name.result)

  // Merging additional tags provided as part to input variables
  tags = merge({ "baseName" = local.base_name }, var.tags)

  // Private DNS Zones Map
  private_dns_names_map = {
    "Sql"   = "privatelink.sql.azuresynapse.net"
    "Dev"   = "privatelink.dev.azuresynapse.net"
    "Web"   = "privatelink.azuresynapse.net"
    "blob"  = "privatelink.blob.core.windows.net"
    "dfs"   = "privatelink.dfs.core.windows.net"
    "vault" = "privatelink.vaultcore.azure.net"
  }

  // VNet variables
  virtual_network_name         = "vnet-${local.base_name}"
  private_endpoint_subnet_name = "snet-${local.base_name}-pe"
  azure_bastion_subnet_name    = "AzureBastionSubnet"

  // Azure Storage variables
  storage_account_names = {
    "0" = "st1${local.base_name}"
    "1" = "st2${local.base_name}"
  }
  default_container_name = "container001"
  private_dns_names_map_for_storage = {
    "blob" = "privatelink.blob.core.windows.net"
    "dfs"  = "privatelink.dfs.core.windows.net"
  }

  // Azyre Key Vault variables
  key_vault_name                  = "kv-${local.base_name}"
  key_vault_private_endpoint_name = "pe-kv-vault-${local.base_name}"

  // Azure Synapse variables
  synapse_workspace_name              = "synw-${local.base_name}"
  synapse_managed_resource_group_name = "mrg-syn-${local.base_name}"
  synapse_private_link_hub_name       = "synplhub${local.base_name}"
  synapse_sql_pool_name               = "syndp001"
  synapse_spark_pool_name             = "synsp001"
  synapse_private_dns_zone_map = {
    "Sql"         = "privatelink.sql.azuresynapse.net"
    "Dev"         = "privatelink.dev.azuresynapse.net"
    "Web"         = "privatelink.azuresynapse.net"
    "SqlOnDemand" = "privatelink.sql.azuresynapse.net"
  }
}
