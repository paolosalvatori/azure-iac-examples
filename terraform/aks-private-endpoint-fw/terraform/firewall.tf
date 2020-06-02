locals {
  fw_pip_name = "${var.prefix}-fw-pip"
  fw_name     = "${var.prefix}-fw"
}

resource azurerm_public_ip "az_firewall_pip" {
  name                = local.fw_pip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource azurerm_firewall "az_firewall" {
  name                = local.fw_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_subnet_2.id
    public_ip_address_id = azurerm_public_ip.az_firewall_pip.id
  }

  tags = var.tags
}
