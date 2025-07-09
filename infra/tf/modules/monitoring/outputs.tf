output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_key" {
  description = "Log Analytics workspace primary shared key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "application_insights_id" {
  description = "Application Insights ID"
  value       = var.monitoring_level != "basic" ? azurerm_application_insights.main[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = var.monitoring_level != "basic" ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "data_collection_rule_id" {
  description = "Data Collection Rule ID for Container Insights"
  value       = var.monitoring_level != "basic" ? azurerm_monitor_data_collection_rule.container_insights[0].id : null
}
