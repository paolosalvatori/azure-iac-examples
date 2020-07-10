locals {
  ws_name = "${var.prefix}-ws"
}

resource "random_uuid" "az_monitor_uuid" { }

resource azurerm_log_analytics_workspace "workspace" {
  name                = local.ws_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = var.tags
}
