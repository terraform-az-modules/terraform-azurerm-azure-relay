##-----------------------------------------------------------------------------
## Tagging Module – Applies standard tags to all resources
##-----------------------------------------------------------------------------
module "labels" {
  source          = "terraform-az-modules/tags/azurerm"
  version         = "1.0.2"
  name            = var.custom_name == null ? var.name : var.custom_name
  location        = var.location
  environment     = var.environment
  managedby       = var.managedby
  label_order     = var.label_order
  repository      = var.repository
  deployment_mode = var.deployment_mode
  extra_tags      = var.extra_tags

}

##-----------------------------------------------------------------------------
## Relay Namespace
##-----------------------------------------------------------------------------
resource "azurerm_relay_namespace" "main" {
  count               = var.enabled ? 1 : 0
  name                = format(var.resource_position_prefix ? "relay-%s" : "%s-relay", local.name)
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  tags                = module.labels.tags
}

resource "azurerm_relay_namespace_authorization_rule" "main" {
  for_each            = var.enabled ? var.authorization_rules : {}
  name                = each.key
  resource_group_name = var.resource_group_name
  namespace_name      = azurerm_relay_namespace.main[0].name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

##-----------------------------------------------------------------------------
## Hybrid Connections
##-----------------------------------------------------------------------------
resource "azurerm_relay_hybrid_connection" "main" {
  for_each                      = var.enabled ? var.hybrid_connections : {}
  name                          = each.key
  resource_group_name           = var.resource_group_name
  relay_namespace_name          = azurerm_relay_namespace.main[0].name
  requires_client_authorization = each.value.requires_client_authorization
  user_metadata                 = each.value.user_metadata
}

resource "azurerm_relay_hybrid_connection_authorization_rule" "main" {
  for_each               = var.enabled ? local.hybrid_connection_authorization_rules : {}
  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  namespace_name         = azurerm_relay_namespace.main[0].name
  hybrid_connection_name = azurerm_relay_hybrid_connection.main[each.value.hybrid_connection_key].name
  listen                 = each.value.listen
  send                   = each.value.send
  manage                 = each.value.manage
}

##-----------------------------------------------------------------------------
## Role Assignments – Entra ID access to the namespace or a hybrid connection
##-----------------------------------------------------------------------------
resource "azurerm_role_assignment" "main" {
  for_each             = var.enabled ? var.role_assignments : {}
  scope                = each.value.hybrid_connection_key == null ? azurerm_relay_namespace.main[0].id : azurerm_relay_hybrid_connection.main[each.value.hybrid_connection_key].id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

##-----------------------------------------------------------------------------
## Private Endpoint
##-----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "pep" {
  count               = var.enabled && var.enable_private_endpoint ? 1 : 0
  name                = format(var.resource_position_prefix ? "pe-relay-%s" : "%s-pe-relay", local.name)
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = module.labels.tags

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids == null ? [] : [var.private_dns_zone_ids]

    content {
      name                 = format(var.resource_position_prefix ? "relay-dns-zone-group-%s" : "%s-relay-dns-zone-group", local.name)
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }

  private_service_connection {
    name                           = format(var.resource_position_prefix ? "psc-relay-%s" : "%s-psc-relay", local.name)
    is_manual_connection           = false
    private_connection_resource_id = azurerm_relay_namespace.main[0].id
    subresource_names              = ["namespace"]
  }
}

##-----------------------------------------------------------------------------
## Diagnostic Settings - Default is "false"
##-----------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                          = var.enabled && var.enable_diagnostic ? 1 : 0
  name                           = format(var.resource_position_prefix ? "diag-log-%s" : "%s-diag-log", azurerm_relay_namespace.main[0].name)
  target_resource_id             = azurerm_relay_namespace.main[0].id
  storage_account_id             = var.storage_account_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id

  dynamic "enabled_metric" {
    for_each = var.metric_enabled ? ["AllMetrics"] : []

    content {
      category = enabled_metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = var.log_enabled ? ["allLogs"] : []

    content {
      category_group = enabled_log.value
    }
  }
}
