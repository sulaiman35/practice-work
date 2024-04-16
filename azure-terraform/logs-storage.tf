resource "random_integer" "name" {
  min = 1000
  max = 9999
}

resource "azurerm_storage_account" "logs" {
  count = local.enable_service_logs ? 1 : 0

  name                      = "${replace(local.resource_prefix, "-", "")}logs${random_integer.name.result}"
  resource_group_name       = local.resource_group.name
  location                  = local.resource_group.location
  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  tags = local.tags
}

resource "azurerm_storage_account_network_rules" "logs" {
  count = local.enable_service_logs ? 1 : 0

  storage_account_id         = azurerm_storage_account.logs[0].id
  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = [azurerm_subnet.web_app_service_infra_subnet[0].id]
  ip_rules                   = local.service_log_ipv4_allow_list

}

resource "azurerm_storage_container" "logs" {
  for_each = local.enable_service_logs ? local.service_log_types : []

  name                  = "${local.resource_prefix}-${each.value}-logs"
  storage_account_name  = azurerm_storage_account.logs[0].name
  container_access_type = "private"
}

resource "azurerm_monitor_diagnostic_setting" "logs" {
  count = local.enable_service_logs ? 1 : 0

  name                           = "${local.resource_prefix}-storage-diag"
  target_resource_id             = azurerm_storage_account.logs[0].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.web_app_service.id
  log_analytics_destination_type = "Dedicated"

  metric {
    category = "Transaction"
  }
}

data "azurerm_storage_account_blob_container_sas" "logs" {
  for_each = local.enable_service_logs ? local.service_log_types : []

  connection_string = azurerm_storage_account.logs[0].primary_connection_string
  container_name    = azurerm_storage_container.logs[each.value].name
  https_only        = true
  start             = local.service_log_storage_sas_start != "" ? local.service_log_storage_sas_start : formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  expiry            = local.service_log_storage_sas_expiry != "" ? local.service_log_storage_sas_expiry : formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timeadd(timestamp(), "+8760h")) # +12 months

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}
