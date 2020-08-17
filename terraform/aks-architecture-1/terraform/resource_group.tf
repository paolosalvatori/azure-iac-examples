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

resource azurerm_resource_group "mgmt_rg" {
    name = var.mgmt_resource_group_name
    location = var.location
    tags = var.tags
}

resource azurerm_resource_group "prod_aks_rg" {
    name = var.prod_aks_resource_group_name
    location = var.location
    tags = var.tags
}

resource azurerm_resource_group "nonprod_aks_rg" {
    name = var.nonprod_aks_resource_group_name
    location = var.location
    tags = var.tags
}