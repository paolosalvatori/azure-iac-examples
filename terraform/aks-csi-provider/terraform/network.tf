locals {
  vnet_name = "${var.prefix}-vnet"
  gateway_subnet_name = "GatewaySubnet"
  aks_subnet_name = "AKSSubnet"
}

# vnets
resource azurerm_virtual_network "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  tags                = var.tags
}

resource azurerm_subnet "gwy_subnet" {
  name                 = local.gateway_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource azurerm_subnet "aks_subnet" {
  name                 = local.aks_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
