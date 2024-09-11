output "storage_container_name" {
  value = azurerm_storage_container.container.name
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_account_primary_dfs_endpoint" {
  value = azurerm_storage_account.storage.primary_dfs_endpoint
}

output "keyvault_id" {
  value = azurerm_key_vault.kv.id
}

output "keyvault_name" {
  value = azurerm_key_vault.kv.name
}

output "keyvault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "fabric_capacity_name" {
  value = module.capacity.capacity_name
}

output "security_group_id" {
  value = azuread_group.sg.id
}

output "security_group_display_name" {
  value = azuread_group.sg.display_name
}