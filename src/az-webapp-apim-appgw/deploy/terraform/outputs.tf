output "web_app_name" {
  value = local.web_app_name
}

output "web_app_plan_name" {
  value = module.app-service.azure_app_service_plan_name
}
output "vnet_name" {
  value = module.vnet.network_details.name
}
