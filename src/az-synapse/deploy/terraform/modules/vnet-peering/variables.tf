variable "virtual_network_name" {
  type = string
  description = "The name of the source Virtual Network."
}

variable "resource_group_name" {
  type = string
  description = "The resource group name of the Virtual Network."
}

variable "remote_virtual_network_name" {
  type = string
  description = "The name of the remote Virtual Network."
}

variable "remote_virtual_network_id" {
  type = string
  description = "The id of the remote Virtual Network."
}
