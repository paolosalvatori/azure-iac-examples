resource "azurerm_api_management" "apim" {
  name                = lower("${var.prefix}-apim-${random_string.random.result}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "My Company"
  publisher_email     = "company@terraform.io"

  sku_name             = "Premium_1"
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.subnet_3.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "apim_dns_private_zone" {
  name                = "azure-api.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "apim_zone_to_vnet_link" {
  name                  = "apim-vnet-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.apim_dns_private_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
} 