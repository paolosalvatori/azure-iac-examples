locals {
  ws_name = "${var.prefix}"
}

resource "random_id" "log_analytics_workspace_unique_name" {
  byte_length = 8
}

resource azurerm_log_analytics_workspace "workspace" {
  name                = "${local.ws_name}-${lower(random_id.log_analytics_workspace_unique_name.hex)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = var.tags
}
