locals {
  dns_storage_blob_private_link  = "privatelink.blob.core.windows.net"
  dns_storage_queue_private_link = "privatelink.queue.core.windows.net"
  dns_storage_table_private_link = "privatelink.table.core.windows.net"
  dns_storage_file_private_link  = "privatelink.file.core.windows.net"
}

# Create the primary storage account.
resource "azurerm_storage_account" "st" {
  name                = var.azurerm_storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  account_tier             = var.azurerm_storage_account_account_tier
  account_kind             = var.azurerm_storage_account_account_kind
  account_replication_type = var.azurerm_storage_account_replication_type
}

data "azurerm_private_dns_zone" "blob_privatelink" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_storage_blob_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "blob_privatelink" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_storage_blob_private_link
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_privatelink" {
  name                  = "${var.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? var.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.blob_privatelink[0].name : data.azurerm_private_dns_zone.blob_privatelink[0].name
  virtual_network_id    = var.azurerm_private_dns_zone_virtual_network_id
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = var.azurerm_private_endpoint_storage_blob_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  subnet_id = var.azurerm_private_endpoint_storage_endpoint_subnet_id

  private_service_connection {
    name = var.azurerm_private_endpoint_storage_blob_service_connection_name

    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false

    subresource_names = [
      "blob"
    ]
  }

  private_dns_zone_group {
    name                 = "storage-blob-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.blob_privatelink[0].id] : [data.azurerm_private_dns_zone.blob_privatelink[0].id]
  }
}

# ---- Queue Private Endpoint ----

data "azurerm_private_dns_zone" "queue_privatelink" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_storage_queue_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "queue_privatelink" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_storage_queue_private_link
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue_privatelink" {
  name                  = "${var.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? var.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.queue_privatelink[0].name : data.azurerm_private_dns_zone.queue_privatelink[0].name
  virtual_network_id    = var.azurerm_private_dns_zone_virtual_network_id
}

resource "azurerm_private_endpoint" "storage_queue" {
  name                = var.azurerm_private_endpoint_storage_queue_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  subnet_id = var.azurerm_private_endpoint_storage_endpoint_subnet_id

  private_service_connection {
    name = var.azurerm_private_endpoint_storage_queue_service_connection_name

    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false

    subresource_names = [
      "queue"
    ]
  }

  private_dns_zone_group {
    name                 = "storage-blob-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.queue_privatelink[0].id] : [data.azurerm_private_dns_zone.queue_privatelink[0].id]
  }
}

# ---- File Private Endpoint ----

data "azurerm_private_dns_zone" "file_privatelink" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_storage_file_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "file_privatelink" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_storage_file_private_link
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_privatelink" {
  name                  = "${var.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? var.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.file_privatelink[0].name : data.azurerm_private_dns_zone.file_privatelink[0].name
  virtual_network_id    = var.azurerm_private_dns_zone_virtual_network_id
}

resource "azurerm_private_endpoint" "storage_file" {
  name                = var.azurerm_private_endpoint_storage_file_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  subnet_id = var.azurerm_private_endpoint_storage_endpoint_subnet_id

  private_service_connection {
    name = var.azurerm_private_endpoint_storage_file_service_connection_name

    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false

    subresource_names = [
      "file"
    ]
  }

  private_dns_zone_group {
    name                 = "storage-file-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.file_privatelink[0].id] : [data.azurerm_private_dns_zone.file_privatelink[0].id]
  }
}

# ---- Table Private Endpoint ----

data "azurerm_private_dns_zone" "table_privatelink" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_storage_table_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "table_privatelink" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_storage_table_private_link
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "table_privatelink" {
  name                  = "${var.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? var.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.table_privatelink[0].name : data.azurerm_private_dns_zone.table_privatelink[0].name
  virtual_network_id    = var.azurerm_private_dns_zone_virtual_network_id
}

resource "azurerm_private_endpoint" "storage_table" {
  name                = var.azurerm_private_endpoint_storage_table_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  subnet_id = var.azurerm_private_endpoint_storage_endpoint_subnet_id

  private_service_connection {
    name = var.azurerm_private_endpoint_storage_table_service_connection_name

    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false

    subresource_names = [
      "table"
    ]
  }

  private_dns_zone_group {
    name                 = "storage-table-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.table_privatelink[0].id] : [data.azurerm_private_dns_zone.table_privatelink[0].id] //[azurerm_private_dns_zone.table_privatelink.id]
  }
}
