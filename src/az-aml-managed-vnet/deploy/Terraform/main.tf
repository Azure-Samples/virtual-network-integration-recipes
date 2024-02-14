data "azurerm_client_config" "current" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = "1.11.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}

resource "azurerm_resource_group" "default" {
  name     = "${var.prefix}mvnetrg"
  location = var.location
}

resource "random_integer" "suffix" {
  min = 10000000
  max = 99999999
}
