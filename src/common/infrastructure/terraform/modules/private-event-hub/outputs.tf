output "event_hub_details" {
  value = {
    event_hub_name    = azurerm_eventhub.evh.name
    connection_string = azurerm_eventhub_namespace.evhns.default_primary_connection_string
  }
}
