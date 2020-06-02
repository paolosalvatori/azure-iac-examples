resource azurerm_firewall_network_rule_collection "az_network_rules" {
  name                = "network-rules"
  azure_firewall_name = azurerm_firewall.az_firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "allow time service"

    source_addresses = [
      azurerm_virtual_network.hub_vnet.address_space[0],
      azurerm_virtual_network.spoke_vnet.address_space[0],
    ]

    destination_ports = [
      "123",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "UDP"
    ]
  }

  rule {
    name = "allow dns service"

    source_addresses = [
      azurerm_virtual_network.hub_vnet.address_space[0],
      azurerm_virtual_network.spoke_vnet.address_space[0],
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "TCP",
      "UDP"
    ]
  }

  rule {
    name = "allow tagged services"

    source_addresses = [
      azurerm_virtual_network.hub_vnet.address_space[0],
      azurerm_virtual_network.spoke_vnet.address_space[0],
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "AzureContainerRegistry",
      "MicrosoftContainerRegistry",
      "AzureActiveDirectory"
    ]

    protocols = [
      "TCP",
      "UDP"
    ]
  }
}

resource azurerm_firewall_application_rule_collection "az_application_rules" {
  name                = "application-rules"
  azure_firewall_name = azurerm_firewall.az_firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "aks-services"

    source_addresses = [
      azurerm_virtual_network.hub_vnet.address_space[0],
    ]

    target_fqdns = [
      "dc.services.visualstudio.com",
      "*.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.microsoftonline.com",
      "*.monitoring.azure.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "*.cdn.mscr.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "acs-mirror.azureedge.net"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }

  rule {
    name = "osupdates"

    source_addresses = [
      azurerm_virtual_network.hub_vnet.address_space[0],
      azurerm_virtual_network.spoke_vnet.address_space[0],
    ]

    target_fqdns = [
      "download.opensuse.org",
      "security.ubuntu.com",
      "packages.microsoft.com",
      "snapcraft.io"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}
