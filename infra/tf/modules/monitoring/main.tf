# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

# Application Insights (for enhanced/full monitoring)
resource "azurerm_application_insights" "main" {
  count               = var.monitoring_level != "basic" ? 1 : 0
  name                = "${var.environment}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

# Data Collection Rule for Container Insights
resource "azurerm_monitor_data_collection_rule" "container_insights" {
  count               = var.monitoring_level != "basic" ? 1 : 0
  name                = "${var.environment}-container-insights-dcr"
  resource_group_name = var.resource_group_name
  location            = var.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_name = "ContainerInsights"
      name           = "ContainerInsightsExtension"
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          enableContainerLogV2   = true
        }
      })
    }
  }

  tags = var.tags
}

# Alert Rules for Full Monitoring
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  count               = var.monitoring_level == "full" ? 1 : 0
  name                = "${var.environment}-aks-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_log_analytics_workspace.main.id]
  description         = "Alert when CPU usage exceeds threshold"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "memory_alert" {
  count               = var.monitoring_level == "full" ? 1 : 0
  name                = "${var.environment}-aks-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_log_analytics_workspace.main.id]
  description         = "Alert when memory usage exceeds threshold"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.main[0].id
  }

  tags = var.tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  count               = var.monitoring_level == "full" ? 1 : 0
  name                = "${var.environment}-aks-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "${var.environment}aks"

  # Add email notifications as needed
  # email_receiver {
  #   name          = "admin"
  #   email_address = "admin@example.com"
  # }

  tags = var.tags
}
