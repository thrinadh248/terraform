resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_service_plan" "asp" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"  # Change to a supported SKU
}

resource "random_string" "suffix" {
  length  = 24
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "thrinadh8888"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on               = [azurerm_resource_group.rg]
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_application_insights" "ai" {
  name                = var.application_insights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  depends_on          = [azurerm_log_analytics_workspace.law]
}

resource "azurerm_linux_function_app" "fa" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  site_config {
    always_on = true  # This can be kept only if the App Service Plan supports it
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME                = "dotnet"
    APPINSIGHTS_INSTRUMENTATIONKEY          = azurerm_application_insights.ai.instrumentation_key
    APPINSIGHTS_PROFILERFEATURE_VERSION     = "disabled"
    APPINSIGHTS_SNAPSHOTFEATURE_VERSION     = "disabled"
    ApplicationInsightsAgent_EXTENSION_VERSION = "~2"
    DiagnosticServices_EXTENSION_VERSION    = "disabled"
    InstrumentationEngine_EXTENSION_VERSION = "disabled"
    XDT_MicrosoftApplicationInsights_BaseExtensions = "disabled"
    XDT_MicrosoftApplicationInsights_Mode   = "disabled"
  }
  depends_on = [azurerm_application_insights.ai]
}

resource "azurerm_monitor_action_group" "action_group" {
  name                = "thrinadh-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "thrinadh-ag"

  email_receiver {
    name          = "thrinadh-email"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "query_alert" {
  name                = "thrinadh-kql-alert"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  data_source_id      = azurerm_log_analytics_workspace.law.id

  query = <<-QUERY
    let FunctionAppName = '${var.function_app_name}';
    let Sensitivity = 1;
    let Seasonality = -1;
    requests
    | where cloud_RoleName == FunctionAppName
    | summarize TotalFailures = countif(success == false) by bin(timestamp, 1h)
    | order by timestamp asc
    | summarize Timestamps = make_list(timestamp), TotalFailures = make_list(TotalFailures)
    | extend (AnomalyScore, IsAnomaly, ExpectedValue) = series_decompose_anomalies(TotalFailures, Sensitivity, Seasonality)
    | mv-expand Timestamps, TotalFailures, AnomalyScore, IsAnomaly, ExpectedValue
    | project timestamp = todatetime(Timestamps), TotalFailures = toint(TotalFailures), AnomalyScore = todouble(AnomalyScore), IsAnomaly = tobool(IsAnomaly), ExpectedValue = todouble(ExpectedValue)
    | order by timestamp desc
  QUERY

  description = "Anomaly detection for function app failures"
  enabled     = true
  frequency   = 60 # in minutes
  severity    = 2
  time_window = 60 # in minutes

  action {
    action_group = [azurerm_monitor_action_group.action_group.id]
  }

  trigger {
    operator  = "GreaterThan"
    threshold = 1
  }

  depends_on = [azurerm_log_analytics_workspace.law]
}

resource "azurerm_monitor_metric_alert" "metric_alert_http5xx" {
  name                = "thrinadh-metric-alert-http5xx"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_function_app.fa.id]

  criteria {
    metric_namespace = "microsoft.web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }

  description = "Alert for HTTP 5xx errors"
  frequency   = "PT5M"
  window_size = "PT5M"
  depends_on  = [azurerm_linux_function_app.fa]
}

