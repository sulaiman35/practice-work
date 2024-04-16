resource "azurerm_log_analytics_workspace" "web_app_service" {
  name                = "${local.resource_prefix}-webappservice"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_log_analytics_data_export_rule" "web_app_service" {
  count                   = local.enable_event_hub ? 1 : 0
  name                    = "${local.resource_prefix}-webappservice"
  resource_group_name     = local.resource_group.name
  workspace_resource_id   = azurerm_log_analytics_workspace.web_app_service.id
  destination_resource_id = azurerm_eventhub.web_app_service[0].id
  table_names             = local.eventhub_export_log_analytics_table_names
  enabled                 = true
}

resource "azurerm_eventhub_namespace" "web_app_service" {
  count               = local.enable_event_hub ? 1 : 0
  name                = "${local.resource_prefix}-eventhubnamespace"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "Standard"
  capacity            = 1
  tags                = local.tags
}

resource "azurerm_eventhub" "web_app_service" {
  count               = local.enable_event_hub ? 1 : 0
  name                = "${local.resource_prefix}-webappservice"
  namespace_name      = azurerm_eventhub_namespace.web_app_service[0].name
  resource_group_name = local.resource_group.name
  partition_count     = 2
  message_retention   = 7
}

resource "azurerm_eventhub_consumer_group" "logstash" {
  count               = local.enable_event_hub && local.enable_logstash_consumer ? 1 : 0
  name                = "${local.resource_prefix}-eventhubconsumergroup"
  namespace_name      = azurerm_eventhub_namespace.web_app_service[0].name
  eventhub_name       = azurerm_eventhub.web_app_service[0].name
  resource_group_name = local.resource_group.name
  user_metadata       = "Logstash"
}

resource "azurerm_eventhub_authorization_rule" "listen_only" {
  count               = local.enable_event_hub && local.enable_logstash_consumer ? 1 : 0
  name                = "${local.resource_prefix}-eventhublistenrule"
  namespace_name      = azurerm_eventhub_namespace.web_app_service[0].name
  eventhub_name       = azurerm_eventhub.web_app_service[0].name
  resource_group_name = local.resource_group.name
  listen              = true
  send                = false
  manage              = false
}
