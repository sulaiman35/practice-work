output "environment" {
  value = local.environment
}

output "azurerm_resource_group_default" {
  value       = local.existing_resource_group == "" ? azurerm_resource_group.default[0] : null
  description = "Default Azure Resource Group"
}

output "azurerm_log_analytics_workspace_web_app_service" {
  value       = azurerm_log_analytics_workspace.web_app_service
  description = "Web App Service Log Analytics Workspace"
  sensitive = true
}

output "azurerm_storage_account_logs" {
  value       = local.enable_service_logs ? azurerm_storage_account.logs[0] : null
  description = "Logs Storage Account"
  sensitive = true
}
