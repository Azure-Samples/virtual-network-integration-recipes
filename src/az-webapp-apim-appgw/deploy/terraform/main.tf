# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }

  required_version = "1.3.2"
}

provider "azurerm" {
  features {}
}

provider "random" {
  # Configuration options
}

locals {
  base_name                      = length(var.resourceBaseName) != 0 ? var.resourceBaseName : random_string.base_name.result
  web_app_name                   = "webapp-${local.base_name}"
  resource_group_name            = azurerm_resource_group.rg.name
  virtual_network_name           = "vnet-${local.base_name}"
  frontend_port_name             = "${local.virtual_network_name}-feport"
  frontend_ip_configuration_name = "${local.virtual_network_name}-feip"
  dns_web_app_private_link       = "privatelink.azurewebsites.net"
}

resource "random_string" "base_name" {
  length  = 13
  special = false
  numeric = true
  upper   = false
  keepers = {
    resource_group = var.resource_group_name
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "vnet" {
  source              = "../../../common/infrastructure/terraform/modules/virtual-network/"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  azurerm_virtual_network_address_space = var.vnet_address_prefix
  azurerm_virtual_network_name          = local.virtual_network_name

  azurerm_subnet_app_service_integration_address_prefixes  = var.vnet_subnet_app_service_integration_address_prefixes
  azurerm_subnet_private_endpoints_address_prefixes        = var.vnet_subnet_private_endpoints_address_prefixes
  azurerm_subnet_app_service_integration_subnet_name       = "snet-${local.base_name}-appServiceInt"
  azurerm_subnet_private_endpoints_name                    = "snet-${local.base_name}-privateEndpoints"
  azurerm_subnet_app_service_integration_service_endpoints = []

  azurerm_network_security_group_name = "nsg-${local.base_name}"
}

module "app-insights" {
  source              = "../../../common/infrastructure/terraform/modules/application-insights"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  azurerm_application_insights_name    = "appi-${local.base_name}"
  azurerm_log_analytics_workspace_name = "log-${local.base_name}"
}

module "app-service" {
  source              = "../../../common/infrastructure/terraform/modules/azure-app-service"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  azurerm_app_service_plan_name                             = "plan-${local.base_name}"
  azurerm_app_service_app_name                              = local.web_app_name
  azurerm_app_service_appinsights_instrumentation_key       = "@Microsoft.KeyVault(VaultName=${module.private-key-vault.key_vault_name};SecretName=kvs-${local.base_name}-aikey)"
  azurerm_app_service_virtual_network_integration_subnet_id = module.vnet.network_details.app_service_integration_subnet_id
}

module "private-key-vault" {
  source              = "../../../common/infrastructure/terraform/modules/private-key-vault"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags
  key_vault_name      = "kv-${local.base_name}"

  azurerm_private_endpoint_kv_private_endpoint_name                    = "pe-${local.base_name}-kv"
  azurerm_private_endpoint_kv_private_endpoint_subnet_id               = module.vnet.network_details.private_endpoint_subnet_id
  azurerm_private_endpoint_kv_private_endpoint_service_connection_name = "kv-private-service-connection"
  azurerm_private_dns_zone_virtual_network_id                          = module.vnet.network_details.vnet_id

  dns_zone_resource_group_name = var.newOrExistingDnsZones == "new" ? local.resource_group_name : var.dns_zone_resource_group_name
  newOrExistingDnsZones        = var.newOrExistingDnsZones
}

resource "azurerm_key_vault_access_policy" "kv-func-access-policy" {
  key_vault_id = module.private-key-vault.key_vault_id
  tenant_id    = module.app-service.azure_app_service_tenant_id
  object_id    = module.app-service.azure_app_service_principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_access_policy" "kv-apim-access-policy" {
  key_vault_id = module.private-key-vault.key_vault_id
  tenant_id    = azurerm_api_management.apim.identity[0].tenant_id
  object_id    = azurerm_api_management.apim.identity[0].principal_id

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_access_policy" "kv-appgw-access-policy" {
  key_vault_id = module.private-key-vault.key_vault_id
  tenant_id    = azurerm_user_assigned_identity.appgw-uami.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw-uami.principal_id

  secret_permissions = [
    "Get",
  ]

  certificate_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_secret" "appi-instrumentation-key" {
  name         = "kvs-${local.base_name}-aikey"
  value        = module.app-insights.instrumentation_key
  key_vault_id = module.private-key-vault.key_vault_id
}

resource "azurerm_key_vault_certificate" "gateway-custom-domain-certificate" {
  name         = "gateway-custom-domain-certificate"
  key_vault_id = module.private-key-vault.key_vault_id

  certificate {
    contents = var.gateway_custom_domain_certificate
    password = ""
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_type   = "EC"
      reuse_key  = true
      curve      = "P-256"
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_key_vault_certificate" "portal-custom-domain-certificate" {
  name         = "portal-custom-domain-certificate"
  key_vault_id = module.private-key-vault.key_vault_id

  certificate {
    contents = var.portal_custom_domain_certificate
    password = ""
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_type   = "EC"
      reuse_key  = true
      curve      = "P-256"
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_key_vault_certificate" "management-custom-domain-certificate" {
  name         = "management-custom-domain-certificate"
  key_vault_id = module.private-key-vault.key_vault_id

  certificate {
    contents = var.management_custom_domain_certificate
    password = ""
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_type   = "EC"
      reuse_key  = true
      curve      = "P-256"
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

data "azurerm_private_dns_zone" "sites-private-link" {
  count               = var.newOrExistingDnsZones == "existing" ? 1 : 0
  name                = local.dns_web_app_private_link
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_private_dns_zone" "sites-private-link" {
  count               = var.newOrExistingDnsZones == "new" ? 1 : 0
  name                = local.dns_web_app_private_link
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sites-private-link" {
  name                  = "${var.resource_group_name}-link"
  resource_group_name   = var.newOrExistingDnsZones == "new" ? local.resource_group_name : var.dns_zone_resource_group_name
  private_dns_zone_name = var.newOrExistingDnsZones == "new" ? azurerm_private_dns_zone.sites-private-link[0].name : data.azurerm_private_dns_zone.sites-private-link[0].name
  virtual_network_id    = module.vnet.network_details.vnet_id
}

resource "azurerm_private_endpoint" "sites-private-endpoint" {
  name                = "pe-${local.base_name}-sites"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  subnet_id = module.vnet.network_details.private_endpoint_subnet_id

  private_service_connection {
    name                           = "azurewebsites-private-service-connection"
    private_connection_resource_id = module.app-service.azure_app_service_id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sites-private-dns-zone-group"
    private_dns_zone_ids = var.newOrExistingDnsZones == "new" ? [azurerm_private_dns_zone.sites-private-link[0].id] : [data.azurerm_private_dns_zone.sites-private-link[0].id]
  }
}

resource "azurerm_network_security_group" "apim-nsg" {
  name                = "nsg-${local.base_name}-apim"
  location            = var.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "apim-in"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = var.tags
}

resource "azurerm_subnet" "apim-subnet" {
  name                 = "snet-${local.base_name}-apim"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network_name
  address_prefixes     = [var.vnet_subnet_apim_adddress_prefixes]

  depends_on = [
    module.vnet
  ]
}

resource "azurerm_subnet_network_security_group_association" "apim-subnet-nsg" {
  subnet_id                 = azurerm_subnet.apim-subnet.id
  network_security_group_id = azurerm_network_security_group.apim-nsg.id
}

resource "azurerm_api_management" "apim" {
  name                 = "apim-${local.base_name}"
  resource_group_name  = local.resource_group_name
  location             = var.location
  tags                 = var.tags
  publisher_name       = var.azurerm_api_management_publisher_name
  publisher_email      = var.azurerm_api_management_publisher_email
  virtual_network_type = "Internal"
  sku_name             = var.azurerm_api_management_sku_name

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim-subnet.id
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_api" "weather_forecast" {
  name                  = "WeatherForecast"
  resource_group_name   = local.resource_group_name
  api_management_name   = azurerm_api_management.apim.name
  revision              = "1"
  display_name          = "WeatherForecast"
  path                  = ""
  protocols             = ["https"]
  service_url           = "https://${module.app-service.azure_app_service_default_site_hostname}"
  subscription_required = false
}

resource "azurerm_api_management_api_operation" "get_forecast" {
  operation_id        = "GetForecast"
  api_name            = azurerm_api_management_api.weather_forecast.name
  resource_group_name = local.resource_group_name
  api_management_name = azurerm_api_management.apim.name
  display_name        = "GetForecast"
  method              = "GET"
  url_template        = "/weatherforecast"
  description         = "Retrieves weather forecast."

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_logger" "apim-logger" {
  name                = "apim-logger"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name
  resource_id         = module.app-insights.azurerm_application_insights_id

  application_insights {
    instrumentation_key = module.app-insights.instrumentation_key
  }
}

resource "azurerm_monitor_diagnostic_setting" "apim-diagnostic-setting" {
  name                       = "apiManagementDiagnosticSetting"
  target_resource_id         = azurerm_api_management.apim.id
  log_analytics_workspace_id = module.app-insights.azurerm_log_analytics_workspace_id

  log {
    category = "GatewayLogs"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_api_management_diagnostic" "apim-diagnostic" {
  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = azurerm_api_management.apim.name
  api_management_logger_id = azurerm_api_management_logger.apim-logger.id

  log_client_ip             = true
  always_log_errors         = true
  verbosity                 = "information"
  http_correlation_protocol = "Legacy"
  sampling_percentage       = 100.0
}

resource "azurerm_api_management_custom_domain" "apim-custom-domains" {
  api_management_id = azurerm_api_management.apim.id

  gateway {
    host_name    = var.gateway_custom_domain_hostname
    key_vault_id = azurerm_key_vault_certificate.gateway-custom-domain-certificate.secret_id
  }

  developer_portal {
    host_name    = var.portal_custom_domain_hostname
    key_vault_id = azurerm_key_vault_certificate.portal-custom-domain-certificate.secret_id
  }

  management {
    host_name    = var.management_custom_domain_hostname
    key_vault_id = azurerm_key_vault_certificate.management-custom-domain-certificate.secret_id
  }

  depends_on = [
    azurerm_key_vault_access_policy.kv-apim-access-policy
  ]
}

resource "azurerm_private_dns_zone" "apim-custom-domains-link" {
  name                = var.custom_domain
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "apim-custom-domains-link" {
  name                = "apimcustomdomains_privatelink"
  resource_group_name = local.resource_group_name

  private_dns_zone_name = azurerm_private_dns_zone.apim-custom-domains-link.name
  virtual_network_id    = module.vnet.network_details.vnet_id
}

resource "azurerm_private_dns_a_record" "apim-gateway-private-dns" {
  name                = "api"
  resource_group_name = local.resource_group_name
  tags                = var.tags

  zone_name = azurerm_private_dns_zone.apim-custom-domains-link.name
  records = [
    azurerm_api_management.apim.private_ip_addresses[0]
  ]
  ttl = 3600
}

resource "azurerm_private_dns_a_record" "apim-portal-private-dns" {
  name                = "portal"
  resource_group_name = local.resource_group_name
  tags                = var.tags

  zone_name = azurerm_private_dns_zone.apim-custom-domains-link.name
  records = [
    azurerm_api_management.apim.private_ip_addresses[0]
  ]
  ttl = 3600
}

resource "azurerm_private_dns_a_record" "apim-management-private-dns" {
  name                = "management"
  resource_group_name = local.resource_group_name
  tags                = var.tags

  zone_name = azurerm_private_dns_zone.apim-custom-domains-link.name
  records = [
    azurerm_api_management.apim.private_ip_addresses[0]
  ]
  ttl = 3600
}

resource "azurerm_network_security_group" "appgw-nsg" {
  name                = "nsg-${local.base_name}-appgw"
  location            = var.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "appgw-in"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https-in"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet" "appgw-subnet" {
  name                 = "snet-${local.base_name}-appgw"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network_name
  address_prefixes     = [var.vnet_subnet_appgw_adddress_prefixes]

  depends_on = [
    module.vnet
  ]
}

resource "azurerm_subnet_network_security_group_association" "appgw-subnet-nsg" {
  subnet_id                 = azurerm_subnet.appgw-subnet.id
  network_security_group_id = azurerm_network_security_group.appgw-nsg.id
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${local.base_name}-appgw"
  resource_group_name = local.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_user_assigned_identity" "appgw-uami" {
  name                = "uami-${local.base_name}-appgw"
  resource_group_name = local.resource_group_name
  location            = var.location
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-${local.base_name}"
  resource_group_name = local.resource_group_name
  location            = var.location

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.appgw-uami.id
    ]
  }

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  gateway_ip_configuration {
    name      = "ipconfig-${local.base_name}-appgw"
    subnet_id = azurerm_subnet.appgw-subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  trusted_root_certificate {
    name = "rootcert-${local.base_name}-appgw"
    data = var.trusted_root_certificate
  }

  backend_address_pool {
    name  = "gatewaybackend"
    fqdns = [var.gateway_custom_domain_hostname]
  }

  probe {
    name                = "apimgatewayprobe"
    host                = var.gateway_custom_domain_hostname
    protocol            = "Https"
    path                = "/status-0123456789abcdef"
    interval            = 30
    timeout             = 120
    unhealthy_threshold = 8
  }

  backend_http_settings {
    name                                = "apimPoolGatewaySetting"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 180
    probe_name                          = "apimgatewayprobe"
    trusted_root_certificate_names      = ["rootcert-${local.base_name}-appgw"]
    pick_host_name_from_backend_address = true
  }

  ssl_certificate {
    name                = "gatewaycert"
    key_vault_secret_id = azurerm_key_vault_certificate.gateway-custom-domain-certificate.secret_id
  }

  http_listener {
    name                           = "gatewaylistener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    host_name                      = var.gateway_custom_domain_hostname
    require_sni                    = true
    ssl_certificate_name           = "gatewaycert"
  }

  request_routing_rule {
    name                       = "gatewayrule"
    rule_type                  = "Basic"
    http_listener_name         = "gatewaylistener"
    backend_address_pool_name  = "gatewaybackend"
    backend_http_settings_name = "apimPoolGatewaySetting"
    priority                   = "10"
  }

  backend_address_pool {
    name  = "portalbackend"
    fqdns = [var.portal_custom_domain_hostname]
  }

  probe {
    name                = "apimportalprobe"
    host                = var.portal_custom_domain_hostname
    protocol            = "Https"
    path                = "/signin"
    interval            = 60
    timeout             = 300
    unhealthy_threshold = 8
  }

  backend_http_settings {
    name                                = "apimPoolPortalSetting"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 180
    probe_name                          = "apimportalprobe"
    trusted_root_certificate_names      = ["rootcert-${local.base_name}-appgw"]
    pick_host_name_from_backend_address = true
  }

  ssl_certificate {
    name                = "portalcert"
    key_vault_secret_id = azurerm_key_vault_certificate.portal-custom-domain-certificate.secret_id
  }

  http_listener {
    name                           = "portallistener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    host_name                      = var.portal_custom_domain_hostname
    require_sni                    = true
    ssl_certificate_name           = "portalcert"
  }

  request_routing_rule {
    name                       = "portalrule"
    rule_type                  = "Basic"
    http_listener_name         = "portallistener"
    backend_address_pool_name  = "portalbackend"
    backend_http_settings_name = "apimPoolPortalSetting"
    priority                   = "20"
  }

  backend_address_pool {
    name  = "managementbackend"
    fqdns = [var.management_custom_domain_hostname]
  }

  probe {
    name                = "apimmanagementprobe"
    host                = var.management_custom_domain_hostname
    protocol            = "Https"
    path                = "/ServiceStatus"
    interval            = 60
    timeout             = 300
    unhealthy_threshold = 8
  }

  backend_http_settings {
    name                                = "apimPoolManagementSetting"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 180
    probe_name                          = "apimmanagementprobe"
    trusted_root_certificate_names      = ["rootcert-${local.base_name}-appgw"]
    pick_host_name_from_backend_address = true
  }

  ssl_certificate {
    name                = "managementcert"
    key_vault_secret_id = azurerm_key_vault_certificate.management-custom-domain-certificate.secret_id
  }

  http_listener {
    name                           = "managementlistener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    host_name                      = var.management_custom_domain_hostname
    require_sni                    = true
    ssl_certificate_name           = "managementcert"
  }

  request_routing_rule {
    name                       = "managementrule"
    rule_type                  = "Basic"
    http_listener_name         = "managementlistener"
    backend_address_pool_name  = "managementbackend"
    backend_http_settings_name = "apimPoolManagementSetting"
    priority                   = "30"
  }

  depends_on = [
    azurerm_api_management_custom_domain.apim-custom-domains
  ]
}

resource "azurerm_monitor_diagnostic_setting" "appgw-diagnostic-settings" {
  name                       = "appGatewayDiagnosticSetting"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = module.app-insights.azurerm_log_analytics_workspace_id

  log {
    category = "ApplicationGatewayAccessLog"
    enabled  = true
  }

  log {
    category = "ApplicationGatewayPerformanceLog"
    enabled  = true
  }

  log {
    category = "ApplicationGatewayFirewallLog"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
