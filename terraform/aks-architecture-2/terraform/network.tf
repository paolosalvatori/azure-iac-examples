locals {
  hub_vnet_name           = "${var.prefix}-hub-vnet"
  spoke_prod_vnet_name    = "${var.prefix}-prod-vnet"
  spoke_nonprod_vnet_name = "${var.prefix}-nonprod-vnet"
  hub_to_prod_spoke_peer_name  = "hub-to-prod-spoke"
  hub_to_nonprod_spoke_peer_name  = "hub-to-nonprod-spoke"
  prod_spoke_to_hub_peer_name  = "prod-spoke-to-hub"
  nonprod_spoke_to_hub_peer_name  = "nonprod-spoke-to-hub"
  private_dns_vnet_link   = "hub-vnet-private-dns-link"
}

# vnets
resource azurerm_virtual_network "hub_vnet" {
  for_each = { for vnet in var.vnets : vnet.name => vnet }

  resource_group_name = azurerm_resource_group.rg["vnet-rg"].name
  name                = each.value.name
  address_space       = each.value.address_space
  location            = var.location
  tags                = var.tags
}


/* resource azurerm_virtual_network "hub_vnet" {
  resource_group_name = azurerm_resource_group.vnet_rg.name
  name                = local.hub_vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  tags                = var.tags
}

resource azurerm_virtual_network "prod_spoke_vnet" {
  resource_group_name = azurerm_resource_group.vnet_rg.name
  name                = local.spoke_prod_vnet_name
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  tags                = var.tags
}

resource azurerm_virtual_network "nonprod_spoke_vnet" {
  resource_group_name = azurerm_resource_group.vnet_rg.name
  name                = local.spoke_nonprod_vnet_name
  address_space       = ["10.2.0.0/16"]
  location            = var.location
  tags                = var.tags
}

resource azurerm_subnet "hub_subnet_1" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource azurerm_subnet "hub_subnet_2" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource azurerm_subnet "hub_subnet_3" {
  name                 = "BastionSubnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource azurerm_subnet "hub_subnet_4" {
  name                 = "AppGatewaySubnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource azurerm_subnet_route_table_association "hub_subnet_3_route_table" {
  subnet_id      = azurerm_subnet.hub_subnet_3.id
  route_table_id = azurerm_route_table.firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet "prod_spoke_subnet_1" {
  name                 = "prod-aks-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.prod_spoke_vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource azurerm_subnet "prod_spoke_subnet_2" {
  name                 = "prod-web-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.prod_spoke_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource azurerm_subnet "prod_spoke_subnet_3" {
  name                 = "prod-sql-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.prod_spoke_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource azurerm_subnet "nonprod_spoke_subnet_1" {
  name                 = "nonprod-aks-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.nonprod_spoke_vnet.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource azurerm_subnet "nonprod_spoke_subnet_2" {
  name                 = "nonprod-web-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.nonprod_spoke_vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource azurerm_subnet "nonprod_spoke_subnet_3" {
  name                 = "nonprod-sql-subnet"
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.nonprod_spoke_vnet.name
  address_prefixes     = ["10.2.2.0/24"]
}

resource azurerm_subnet_route_table_association "prod_spoke_subnet_1_route_table_assoc" {
  subnet_id      = azurerm_subnet.prod_spoke_subnet_1.id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "prod_spoke_subnet_2_route_table_assoc" {
  subnet_id      = azurerm_subnet.prod_spoke_subnet_2.id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "prod_spoke_subnet_3_route_table_assoc" {
  subnet_id      = azurerm_subnet.prod_spoke_subnet_3.id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "nonprod_spoke_subnet_1_route_table_assoc" {
  subnet_id      = azurerm_subnet.nonprod_spoke_subnet_1.id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "nonprod_spoke_subnet_2_route_table_assoc" {
  subnet_id      = azurerm_subnet.nonprod_spoke_subnet_2.id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "nonprod_spoke_subnet_3_route_table_assoc" {
  subnet_id      = azurerm_subnet.nonprod_spoke_subnet_3.id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_virtual_network_peering "hub_prod_spoke_peer" {
  name                         = local.hub_to_prod_spoke_peer_name
  resource_group_name          = azurerm_resource_group.vnet_rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.prod_spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true

  depends_on = [
    azurerm_virtual_network_gateway.vpngwy,
  ]
}

resource azurerm_virtual_network_peering "hub_nonprod_spoke_peer" {
  name                         = local.hub_to_nonprod_spoke_peer_name
  resource_group_name          = azurerm_resource_group.vnet_rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.nonprod_spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true

  depends_on = [
    azurerm_virtual_network_gateway.vpngwy,
  ]
}

resource azurerm_virtual_network_peering "prod_spoke_hub_peer" {
  name                         = local.prod_spoke_to_hub_peer_name
  resource_group_name          = azurerm_resource_group.vnet_rg.name
  virtual_network_name         = azurerm_virtual_network.prod_spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = true

  depends_on = [
    azurerm_virtual_network_gateway.vpngwy,
  ]
}

resource azurerm_virtual_network_peering "nonprod_spoke_hub_peer" {
  name                         = local.nonprod_spoke_to_hub_peer_name
  resource_group_name          = azurerm_resource_group.vnet_rg.name
  virtual_network_name         = azurerm_virtual_network.nonprod_spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = true

  depends_on = [
    azurerm_virtual_network_gateway.vpngwy,
  ]
}
*/