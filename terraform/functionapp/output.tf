output "function_app_name" {
  value = azurerm_linux_function_app.fa.name
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.ai.instrumentation_key
  sensitive = true
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "alert_email" {
  value = var.alert_email
}

