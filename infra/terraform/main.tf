provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = ""
}

variable "base_name" {
  description = "Base name for all resources"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure Location"
  type        = string
  default     = ""
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg${var.base_name}"
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "st${var.base_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "raw" {
  name                  = "raw"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "kv" {
  name                        = "kv${var.base_name}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
}

resource "azurerm_application_insights" "appinsights" {
  name                = "ai${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_machine_learning_workspace" "azureml" {
  name                = "aml${var.base_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_name            = "Basic"
  application_insights_id = azurerm_application_insights.appinsights.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "cosmos${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "database" {
  name                = "db${var.base_name}"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "container${var.base_name}"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.database.name

  partition_key_paths = ["/partitionKey"]
  throughput          = 400
}

resource "azurerm_api_management" "apim" {
  name                = "apim${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Your Publisher Name"
  publisher_email     = "your-email@example.com"
  sku_name            = "Developer_1"
}

