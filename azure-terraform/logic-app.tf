resource "azurerm_logic_app_workflow" "webhook" {
  count = local.enable_monitoring && local.existing_logic_app_workflow.name == "" ? 1 : 0

  name                = "${local.resource_prefix}-webhook-workflow"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  tags = local.tags
}

resource "azurerm_logic_app_trigger_http_request" "webhook" {
  count = local.enable_monitoring && local.existing_logic_app_workflow.name == "" ? 1 : 0

  name         = "${local.resource_prefix}-trigger"
  logic_app_id = azurerm_logic_app_workflow.webhook[0].id

  schema = templatefile("${path.module}/schema/common-alert-schema.json", {})
}

resource "azurerm_logic_app_action_custom" "var_affected_resource" {
  count = local.enable_monitoring && local.existing_logic_app_workflow.name == "" ? 1 : 0

  name         = "${local.resource_prefix}-setvars0"
  logic_app_id = azurerm_logic_app_workflow.webhook[0].id

  body = <<BODY
  {
    "description": "Affected resource",
    "inputs": {
      "variables": [{
        "name": "affectedResource",
        "type": "array",
        "value": "@split(triggerBody()?['data']?['essentials']?['alertTargetIDs'][0], '/')"
      }]
    },
    "runAfter": {},
    "type": "InitializeVariable"
  }
  BODY
}

resource "azurerm_logic_app_action_custom" "var_alarm_context" {
  count = local.enable_monitoring && local.existing_logic_app_workflow.name == "" ? 1 : 0

  name         = "${local.resource_prefix}-setvars1"
  logic_app_id = azurerm_logic_app_workflow.webhook[0].id

  body = <<BODY
  {
    "description": "Alarm context",
    "inputs": {
      "variables": [{
        "name": "alarmContext",
        "type": "object",
        "value": "@triggerBody()?['data']?['alertContext']['condition']['allOf'][0]"
      }]
    },
    "runAfter": {
      "${azurerm_logic_app_action_custom.var_affected_resource[0].name}": [
        "Succeeded"
      ]
    },
    "type": "InitializeVariable"
  }
  BODY
}

resource "azurerm_logic_app_action_http" "slack" {
  count = local.enable_monitoring && local.existing_logic_app_workflow.name == "" && local.monitor_enable_slack_webhook ? 1 : 0

  name         = "${local.resource_prefix}-action"
  logic_app_id = azurerm_logic_app_workflow.webhook[0].id
  method       = "POST"
  uri          = local.monitor_slack_webhook_receiver
  headers = {
    "Content-Type" : "application/json"
  }

  run_after {
    action_name   = azurerm_logic_app_action_custom.var_alarm_context[0].name
    action_result = "Succeeded"
  }

  body = templatefile(
    "${path.module}/webhook/slack.json",
    {
      channel = local.monitor_slack_channel
    }
  )
}

resource "azurerm_monitor_diagnostic_setting" "webhook" {
  count = local.enable_monitoring && local.existing_logic_app_workflow.name == "" ? 1 : 0

  name               = "${local.resource_prefix}-webhook-diag"
  target_resource_id = azurerm_logic_app_workflow.webhook[0].id

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.web_app_service.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "WorkflowRuntime"
  }

  metric {
    category = "AllMetrics"
  }
}
