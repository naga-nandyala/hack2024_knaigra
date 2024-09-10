# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "=2.91.0"
#     }
#   }
# }

provider "azurerm" {
  subscription_id = var.subscription_id
  features {

  }
}

locals {
  base_name = var.base_name
  tags      = { environment : "dev" }
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.base_name}-rg"
  location = var.location
  tags     = { environment = "dev" }
}

module "adls" {
  source               = "./modules/adls"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_name = "st${local.base_name}"
  container_name       = "raw"
  tags                 = local.tags
}