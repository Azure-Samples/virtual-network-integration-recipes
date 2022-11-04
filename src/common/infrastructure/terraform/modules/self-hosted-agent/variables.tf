variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Azure resources."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources exist."
}

variable "azurerm_virtual_network_name" {
  type        = string
  description = "The name of the Azure virtual network."
}

variable "azurerm_virtual_network_address_space" {
  type        = string
  description = "The address space that is used the virtual network."
}

variable "azurerm_subnet_aci_subnet_name" {
  type        = string
  description = "The name of the virtual network subnet used for the Azure container instance."
}

variable "azurerm_subnet_aci_address_prefixes" {
  type        = string
  description = "The virtual network address prefix to use for the Azure container instance."
}

variable "azure_devops_personal_access_token" {
  type        = string
  description = "The PAT used to connect to the Azure DevOps instance."
  sensitive   = true
}

variable "azure_devops_org_name" {
  type        = string
  description = "The Azure DevOps organization."
}

variable "azure_devops_agent_pool_name" {
  type        = string
  description = "The Azure DevOps agent pool to deploy agents to."
}

variable "agent_count" {
  type        = string
  description = "The number of agents to deploy to the agent pool"
}

variable "agent_prefix" {
  type        = string
  description = "The prefix for the Azure Container Instance resource used as an Azure DevOps self-hosted agent."
  default     = "linuxagent"
}

variable "image_path" {
  type        = string
  description = "The path of the image to build."
}

variable "image_name" {
  type        = string
  description = "The name of the image to push to ACR."
}

variable "image_tag" {
  type        = string
  description = "The tag of the image to push to ACR."
}

variable "service_principal_client_id" {
  type        = string
  description = "The client id for the service principal."
  sensitive   = true
}

variable "service_principal_client_secret" {
  type        = string
  description = "The client secret for the service principal."
  sensitive   = true
}

variable "service_principal_tenant_id" {
  type        = string
  description = "The tenant of the service principal."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resource."
}

variable "use_existing_acr" {
  type        = bool
  description = "Specifies whether the Azure container registry was pre-provisioned. Dictates whether to create a new acr or use the existing one."
}

variable "azurerm_acr_name" {
  type        = string
  description = "The name of the Azure container registry."
}

variable "existing_acr_credentials" {
  type = object({
    login_server   = string
    admin_username = string
    admin_password = string
  })
  description = "The credentials of the acr in which to use for image management. Used if var.use_existing_acr is true."
  default     = null
  sensitive   = true
}

variable "azurerm_network_security_group_name" {
  type        = string
  description = "The name of the network security group."
}
