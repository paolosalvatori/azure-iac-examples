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
