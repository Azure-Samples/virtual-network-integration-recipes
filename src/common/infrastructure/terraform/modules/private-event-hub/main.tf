// Terraform currently (as of February 2022) does not support setting Network Access to 'Disabled' on Event Hub namespaces.
// The module offers the same functionality via the 'Selected Networks' option, restricting traffic from outside the virtual network.
// Please refer to https://github.com/hashicorp/terraform-provider-azurerm/issues/14947 for additional information.

locals {
  dns_service_bus_private_link = "privatelink.servicebus.windows.net"
}

resource "azurerm_eventhub_namespace" "evhns" {
  name                = var.azurerm_eventhub_namespace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku = var.azurerm_eventhub_namespace_sku

  network_rulesets {
    default_action                 = "Deny"
    trusted_service_access_enabled = false

    virtual_network_rule {
      ignore_missing_virtual_network_service_endpoint = false
      subnet_id                                       = var.azurerm_eventhub_namespace_subnet_id
    }
  }
}

resource "azurerm_eventhub" "evh" {
  name                = var.azurerm_eventhub_name
  resource_group_name = var.resource_group_name

  namespace_name    = azurerm_eventhub_namespace.evhns.name
  partition_count   = var.azurerm_eventhub_partition_count
  message_retention = var.azurerm_eventhub_message_retention
}

data "azurerm_private_dns_zone" "evhns-private-link" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_service_bus_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "evhns-private-link" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_service_bus_private_link
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "evhns-private-link" {
  name                  = "${var.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? var.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.evhns-private-link[0].name : data.azurerm_private_dns_zone.evhns-private-link[0].name
  virtual_network_id    = var.azurerm_private_dns_zone_virtual_network_id
}

resource "azurerm_private_endpoint" "evhns-private-endpoint" {
  name                = var.azurerm_private_endpoint_evhns_private_endpoint_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  subnet_id = var.azurerm_private_endpoint_evhns_private_endpoint_subnet_id

  private_service_connection {
    name                           = var.azurerm_private_endpoint_evhns_private_endpoint_service_connection_name
    private_connection_resource_id = azurerm_eventhub_namespace.evhns.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "event-hub-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.evhns-private-link[0].id] : [data.azurerm_private_dns_zone.evhns-private-link[0].id]
  }
}
