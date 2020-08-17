resource azurerm_resource_group "rg" {
    name = var.resource_group_name
    location = var.location
    tags = var.tags
}

resource azurerm_resource_group "vnet_rg" {
    name = var.vnet_resource_group_name
    location = var.location
    tags = var.tags
}