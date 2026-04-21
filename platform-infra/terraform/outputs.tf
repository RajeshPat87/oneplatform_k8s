output "resource_groups" {
  description = "All per-stack RGs created."
  value       = { for k, rg in azurerm_resource_group.stack : k => rg.name }
}

output "aks_name"                  { value = azurerm_kubernetes_cluster.aks.name }
output "aks_resource_group"        { value = azurerm_resource_group.stack["aks"].name }
output "acr_login_server"          { value = azurerm_container_registry.acr.login_server }
output "acr_name"                  { value = azurerm_container_registry.acr.name }
output "key_vault_uri"             { value = azurerm_key_vault.vault.vault_uri }
output "log_analytics_workspace"   { value = azurerm_log_analytics_workspace.obs.name }
output "mlops_storage_account"     { value = azurerm_storage_account.mlops.name }
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
