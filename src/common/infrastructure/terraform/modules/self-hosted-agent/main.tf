resource "azurerm_virtual_network" "vnet" {
  name                = var.azurerm_virtual_network_name
  address_space       = [var.azurerm_virtual_network_address_space]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "aci" {
  name                 = var.azurerm_subnet_aci_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.azurerm_subnet_aci_address_prefixes]

  delegation {
    name = "acidelegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_network_security_group" "aci_nsg" {
  name                = "${var.azurerm_network_security_group_name}-aci"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule = []
}

resource "azurerm_subnet_network_security_group_association" "aci_nsg_association" {
  subnet_id                 = azurerm_subnet.aci.id
  network_security_group_id = azurerm_network_security_group.aci_nsg.id
}

resource "azurerm_container_registry" "acr" {
  count               = var.use_existing_acr == true ? 0 : 1
  name                = var.azurerm_acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

locals {
  acr_login_server   = var.use_existing_acr == true ? var.existing_acr_credentials.login_server : azurerm_container_registry.acr[0].login_server
  acr_admin_username = var.use_existing_acr == true ? var.existing_acr_credentials.admin_username : azurerm_container_registry.acr[0].admin_username
  acr_admin_password = var.use_existing_acr == true ? var.existing_acr_credentials.admin_password : azurerm_container_registry.acr[0].admin_password
}

resource "null_resource" "acr_login" {
  provisioner "local-exec" {
    command = "az login --service-principal --username ${var.service_principal_client_id} --password ${var.service_principal_client_secret} --tenant ${var.service_principal_tenant_id} && az acr login --name ${var.azurerm_acr_name}"
  }
  depends_on = [
    azurerm_container_registry.acr
  ]
}

resource "null_resource" "docker_build" {
  provisioner "local-exec" {
    command = "docker build -t ${local.acr_login_server}/${var.image_name}:${var.image_tag} ${var.image_path}"
  }
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = "docker push ${local.acr_login_server}/${var.image_name}:${var.image_tag}"
  }
  depends_on = [
    null_resource.acr_login,
    null_resource.docker_build
  ]
}

module "aci-devops-agent" {
  source                   = "Azure/aci-devops-agent/azurerm"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  create_resource_group    = false
  enable_vnet_integration  = true
  vnet_resource_group_name = var.resource_group_name
  vnet_name                = azurerm_virtual_network.vnet.name
  subnet_name              = azurerm_subnet.aci.name

  linux_agents_configuration = {
    agent_name_prefix            = var.agent_prefix
    agent_pool_name              = var.azure_devops_agent_pool_name
    count                        = var.agent_count
    docker_image                 = "${local.acr_login_server}/${var.image_name}"
    docker_tag                   = var.image_tag
    cpu                          = 1
    memory                       = 4
    user_assigned_identity_ids   = []
    use_system_assigned_identity = false
  }

  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token

  image_registry_credential = {
    username = local.acr_admin_username
    password = local.acr_admin_password
    server   = local.acr_login_server
  }

  depends_on = [
    null_resource.docker_push
  ]
}
