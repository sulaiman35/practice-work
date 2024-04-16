resource "azurerm_application_insights" "web_app_service" {
  name                = "${local.resource_prefix}-insights"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.web_app_service.id
  retention_in_days   = 30
  tags                = local.tags
}

provider "azurerm" {
  features {}
}


resource "azurerm_monitor_diagnostic_setting" "web_app_service" {
  name                       = "${local.resource_prefix}-webappservice"
  target_resource_id         = local.service_app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.web_app_service.id

  dynamic "enabled_log" {
    for_each = local.service_diagnostic_setting_types
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_application_insights_standard_web_test" "web_app_service" {
  count = local.enable_monitoring ? 1 : 0

  name                    = "${local.resource_prefix}-http"
  resource_group_name     = local.resource_group.name
  location                = local.resource_group.location
  application_insights_id = azurerm_application_insights.web_app_service.id
  timeout                 = 10
  description             = "Regional HTTP availability check"
  enabled                 = true

  geo_locations = [
    "emea-se-sto-edge", # UK West
    "emea-nl-ams-azr",  # West Europe
    "emea-ru-msa-edge"  # UK South
  ]

  request {
    url = local.monitor_http_availability_url

    header {
      name  = "X-AppInsights-HttpTest"
      value = azurerm_application_insights.web_app_service.name
    }
  }

  tags = merge(
    local.tags,
    { "hidden-link:${azurerm_application_insights.web_app_service.id}" = "Resource" },
  )
}

resource "azurerm_monitor_action_group" "web_app_service" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-actiongroup"
  resource_group_name = local.resource_group.name
  short_name          = local.project_name
  tags                = local.tags

  dynamic "email_receiver" {
    for_each = local.monitor_email_receivers

    content {
      name                    = "Email ${email_receiver.value}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "event_hub_receiver" {
    for_each = local.enable_event_hub ? [0] : []

    content {
      name                    = "Event Hub"
      event_hub_name          = azurerm_eventhub.web_app_service[0].name
      event_hub_namespace     = azurerm_eventhub_namespace.web_app_service[0].id
      subscription_id         = data.azurerm_subscription.current.subscription_id
      use_common_alert_schema = true
    }
  }

  dynamic "logic_app_receiver" {
    for_each = local.enable_monitoring || local.existing_logic_app_workflow.name != "" ? [0] : []

    content {
      name                    = local.monitor_logic_app_receiver.name
      resource_id             = local.monitor_logic_app_receiver.resource_id
      callback_url            = local.monitor_logic_app_receiver.callback_url
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_metric_alert" "cpu" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-cpu"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_service_plan.default.id]
  description         = "Action will be triggered when CPU usage is higher than 80% for longer than 5 minutes"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "microsoft.web/serverfarms"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.web_app_service[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "memory" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-memory"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_service_plan.default.id]
  description         = "Action will be triggered when memory usage is higher than 80% for longer than 5 minutes"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "microsoft.web/serverfarms"
    metric_name      = "MemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.web_app_service[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "exceptions" {
  count = local.enable_monitoring ? 1 : 0

  name                 = "${azurerm_application_insights.web_app_service.name}-exceptions"
  resource_group_name  = local.resource_group.name
  location             = local.resource_group.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  scopes               = [azurerm_application_insights.web_app_service.id]
  severity             = 2
  description          = "Action will be triggered when an Exception is raised in App Insights"

  criteria {
    query = <<-QUERY
      exceptions
        | where timestamp > ago(5min)
        | project cloud_RoleInstance, type, outerMessage, innermostMessage
        | summarize ErrorCount=count() by cloud_RoleInstance, type, outerMessage, innermostMessage
        | project ErrorCount, cloud_RoleInstance, type, outerMessage, innermostMessage
        | order by ErrorCount desc
      QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThanOrEqual"

    dimension {
      name     = "ErrorCount"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "cloud_RoleInstance"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "type"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "outerMessage"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "innermostMessage"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled = false

  action {
    action_groups = [azurerm_monitor_action_group.web_app_service[0].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "http" {
  count = local.enable_monitoring ? 1 : 0

  name                = "${local.resource_prefix}-http"
  resource_group_name = local.resource_group.name
  # Scope requires web test to come first
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/8551
  scopes      = [azurerm_application_insights_standard_web_test.web_app_service[0].id, azurerm_application_insights.web_app_service.id]
  description = "Action will be triggered when regional availability becomes impacted."
  severity    = 2

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.web_app_service[0].id
    component_id          = azurerm_application_insights.web_app_service.id
    failed_location_count = 2 # 2 out of 3 locations
  }

  action {
    action_group_id = azurerm_monitor_action_group.web_app_service[0].id
  }

  tags = local.tags
}

resource "azurerm_monitor_metric_alert" "latency" {
  count = local.enable_monitoring && local.enable_cdn_frontdoor ? 1 : 0

  name                = "${azurerm_cdn_frontdoor_profile.cdn[0].name}-latency"
  resource_group_name = local.resource_group.name
  scopes              = [azurerm_cdn_frontdoor_profile.cdn[0].id]
  description         = "Action will be triggered when Origin latency is higher than 1s"
  window_size         = "PT5M"
  frequency           = "PT5M"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "TotalLatency"
    aggregation      = "Minimum"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.web_app_service[0].id
  }

  tags = local.tags
}
