output "function_app_name" {
  value = local.azurerm_function_app_name
}

output "vnet_name" {
  value = module.vnet.network_details.name
}
