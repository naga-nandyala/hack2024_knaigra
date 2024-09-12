provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

provider "azapi" {
  # No configuration needed for azapi provider
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.64.0" # Update to the latest or appropriate version
    }
    azapi = {
      source = "azure/azapi"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
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

variable "fabric_capacity_admin" {
  description = "Fabric Capacity Admin"
  type        = string
  default     = ""
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.base_name}"
  location = var.location
}



resource "azuread_group" "sg" {
  display_name     = "sg${var.base_name}"
  security_enabled = true
}

resource "azuread_group" "sg-chevron" {
  display_name     = "sgchevron${var.base_name}"
  security_enabled = true
}

data "azurerm_role_definition" "contributor_role" {
  name = "Contributor"
}

data "azurerm_role_definition" "storage_blob_contributor_role" {
  name = "Storage Blob Data Contributor"
}



resource "azurerm_role_assignment" "role_assignment_sg" {
  principal_id         = azuread_group.sg.id
  role_definition_name = data.azurerm_role_definition.contributor_role.name
  scope                = azurerm_resource_group.rg.id
}

resource "azurerm_role_assignment" "role_assignment_sg_chevron" {
  principal_id         = azuread_group.sg-chevron.id
  role_definition_name = data.azurerm_role_definition.contributor_role.name
  scope                = azurerm_resource_group.rg.id
}


resource "azurerm_role_assignment" "role_assignment_sg_blob" {
  principal_id         = azuread_group.sg.id
  role_definition_name = data.azurerm_role_definition.storage_blob_contributor_role.name
  scope                = azurerm_resource_group.rg.id
}

resource "azurerm_role_assignment" "role_assignment_sg_chevron_blob" {
  principal_id         = azuread_group.sg-chevron.id
  role_definition_name = data.azurerm_role_definition.storage_blob_contributor_role.name
  scope                = azurerm_resource_group.rg.id
}



resource "azurerm_storage_account" "storage" {
  name                     = "st${var.base_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "container" {
  name                  = "container"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "kv" {
  name                     = "kv1${var.base_name}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
}



data "azuread_client_config" "current" {}


resource "azurerm_key_vault_access_policy" "kv_access_policy_1" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_client_config.current.object_id
  secret_permissions = [
    "Set",
    "Get",
    "Delete",
    "Purge",
    "Recover",
    "List"
  ]
}



resource "azurerm_key_vault_access_policy" "kv_access_policy" {
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azuread_group.sg.object_id
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "kv_access_policy_chevron" {
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azuread_group.sg-chevron.object_id
  secret_permissions = ["Get", "List"]
}


resource "azurerm_application_insights" "appinsights" {
  name                = "appinsights${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

// New Storage Account with HNS disabled for Azure ML
resource "azurerm_storage_account" "ml_storage" {
  name                     = "stml${var.base_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = false # HNS disabled
}

resource "azurerm_machine_learning_workspace" "azureml" {
  name                    = "aml${var.base_name}"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = var.location
  sku_name                = "Basic"
  application_insights_id = azurerm_application_insights.appinsights.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.ml_storage.id # Use the new storage account

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
  name                = "apim1${var.base_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Your Publisher Name"
  publisher_email     = "your-email@example.com"
  sku_name            = "Developer_1"
}

module "capacity" {
  source            = "./modules/fabric/capacity"
  capacity_name     = "cap${var.base_name}"
  resource_group_id = azurerm_resource_group.rg.id
  location          = azurerm_resource_group.rg.location
  admin_email       = var.fabric_capacity_admin
  sku               = "F2"
  tags              = { environment : "dev" }
}



// New Storage Account for AI Hub
resource "azurerm_storage_account" "aihub_storage" {
  name                     = "staihub${var.base_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = false # HNS disabled for AI Hub
}

// AzAPI AIServices
resource "azapi_resource" "AIServicesResource" {
  type      = "Microsoft.CognitiveServices/accounts@2023-10-01-preview"
  name      = "AIServicesResource${var.base_name}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    name = "AIServicesResource${var.base_name}"
    properties = {
      customSubDomainName = "${var.base_name}"
      apiProperties = {
        statisticsEnabled = false
      }
    }
    kind = "AIServices"
    sku = {
      name = "S0"
    }
  })

  response_export_values = ["*"]
}

// Azure AI Hub
resource "azapi_resource" "hub" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  name      = "aihub${var.base_name}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      description    = "This is my Azure AI hub"
      friendlyName   = "My Hub"
      storageAccount = azurerm_storage_account.aihub_storage.id
      keyVault       = azurerm_key_vault.kv.id
    }
    kind = "hub"
  })
}

// Azure AI Project
resource "azapi_resource" "project" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  name      = "aiproject-1-${var.base_name}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      description   = "This is my Azure AI PROJECT"
      friendlyName  = "My Project"
      hubResourceId = azapi_resource.hub.id
    }
    kind = "project"
  })
}

// AzAPI AI Services Connection
resource "azapi_resource" "AIServicesConnection" {
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name      = "Default_AIServices${var.base_name}"
  parent_id = azapi_resource.hub.id

  body = jsonencode({
    properties = {
      category      = "AIServices"
      target        = jsondecode(azapi_resource.AIServicesResource.output).properties.endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azapi_resource.AIServicesResource.id
      }
    }
  })

  response_export_values = ["*"]
}

// CONTAINER REGISTRY
resource "azurerm_container_registry" "acr" {
  name                = "acr${var.base_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = true
}

