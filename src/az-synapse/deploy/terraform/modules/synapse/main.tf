terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.spoke]
    }
  }
}

resource "azurerm_synapse_workspace" "syn-ws" {
  name                = var.synapse_workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  provider            = azurerm.spoke

  identity {
    type = "SystemAssigned"
  }

  storage_data_lake_gen2_filesystem_id = var.synapse_storage_file_system_id
  sql_administrator_login              = var.synapse_sql_administrator_login
  sql_administrator_login_password     = var.synapse_sql_administrator_login_password
  compute_subnet_id                    = var.private_endpoint_subnet_id
  managed_resource_group_name          = var.synapse_managed_resource_group_name
  managed_virtual_network_enabled      = true
  public_network_access_enabled        = false
}

resource "azurerm_synapse_private_link_hub" "syn-pl-hub" {
  name                = var.synapse_private_link_hub_name
  resource_group_name = var.resource_group_name
  location            = var.location
  provider            = azurerm.spoke
  tags                = var.tags
}

resource "azurerm_synapse_spark_pool" "syn-spark-pool" {
  name                 = var.synapse_spark_pool_name
  synapse_workspace_id = azurerm_synapse_workspace.syn-ws.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  tags                 = var.tags
  spark_version        = "2.4"
  provider             = azurerm.spoke

  auto_scale {
    max_node_count = 10
    min_node_count = 3
  }
  auto_pause {
    delay_in_minutes = 15
  }
}

resource "azurerm_synapse_sql_pool" "syn-sql-pool" {
  name                 = var.synapse_sql_pool_name
  synapse_workspace_id = azurerm_synapse_workspace.syn-ws.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  collation            = "SQL_LATIN1_GENERAL_CP1_CI_AS"
  data_encrypted       = true
  provider             = azurerm.spoke
  tags                 = var.tags
}

resource "azurerm_role_assignment" "st-synw-access-default" {
  scope                = var.synapse_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.syn-ws.identity[0].principal_id
  provider             = azurerm.spoke
}

resource "azurerm_role_assignment" "st-synw-access-main" {
  scope                = var.main_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.syn-ws.identity[0].principal_id
  provider             = azurerm.spoke
}

resource "azurerm_private_endpoint" "sites-private-endpoints" {
  for_each            = var.synapse_private_dns_zone_map
  name                = "pe-syn-${each.key}-${var.base_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  subnet_id           = var.private_endpoint_subnet_id
  provider            = azurerm.spoke

  private_service_connection {
    name                           = "plsc-syn-${each.key}-${var.base_name}"
    private_connection_resource_id = each.key == "Web" ? azurerm_synapse_private_link_hub.syn-pl-hub.id : azurerm_synapse_workspace.syn-ws.id
    subresource_names              = [each.key]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "synapse-private-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids[each.key]]
  }
}
