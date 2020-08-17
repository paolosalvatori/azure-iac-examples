resource azurerm_resource_group "rg" {
    name = var.prefix-var.resource_group_name
    location = var.location
    tags = var.tags
}

resource azurerm_resource_group "vnet_rg" {
    name = var.prefix-var.vnet_resource_group_name
    location = var.location
    tags = var.tags
}

resource azurerm_resource_group "mgmt_rg" {
    name = var.prefix-var.mgmt_resource_group_name
    location = var.location
    tags = var.tags
}

resource azurerm_resource_group "prod_aks_rg" {
    name = var.prefix-var.prod_aks_resource_group_name
    location = var.location
    tags = var.tags
}

resource azurerm_resource_group "nonprod_aks_rg" {
    name = var.prefix-var.nonprod_aks_resource_group_name
    location = var.location
    tags = var.tags
}