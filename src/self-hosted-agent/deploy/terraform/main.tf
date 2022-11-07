# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.78.0"
    }
  }

  required_version = "0.15.5"
}

provider "azurerm" {
  features {}
}

locals {
  base_name = var.resourceBaseName
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "self-hosted-agent" {
  source                                = "../../../common/infrastructure/terraform/modules/self-hosted-agent/"
  resource_group_name                   = azurerm_resource_group.rg.name
  location                              = var.location
  azurerm_virtual_network_name          = "vnet-${local.base_name}"
  azurerm_virtual_network_address_space = "10.0.0.0/20"
  use_existing_acr                      = var.use_existing_acr
  azurerm_acr_name                      = var.use_existing_acr == true ? var.existing_acr_name : "acr${local.base_name}"
  existing_acr_credentials              = var.existing_acr_credentials
  azurerm_subnet_aci_subnet_name        = "snet-${local.base_name}-aci"
  azurerm_subnet_aci_address_prefixes   = "10.0.5.0/26"
  azurerm_network_security_group_name   = "nsg-${local.base_name}"
  azure_devops_personal_access_token    = var.azure_devops_personal_access_token
  azure_devops_org_name                 = var.azure_devops_org_name
  azure_devops_agent_pool_name          = var.azure_devops_agent_pool_name
  agent_prefix                          = var.agent_prefix
  agent_count                           = "1"
  image_name                            = "networkintegration"
  image_tag                             = "latest"
  image_path                            = "../dockeragent"
  service_principal_client_id           = var.service_principal_client_id
  service_principal_client_secret       = var.service_principal_client_secret
  service_principal_tenant_id           = var.service_principal_tenant_id
  tags                                  = var.tags
}
