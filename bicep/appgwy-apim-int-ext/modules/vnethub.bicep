param tags object
param suffix string

var vnetName = 'hub-vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AppGatewaySubnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
          delegations: []
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'appGateway-subnet-nsg-${suffix}')
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', 'appgwy-firewall-rt-${suffix}')
          }
        }
      }
      {
        name: 'InfraSubnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', 'default-firewall-rt-${suffix}')
          }
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.3.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
        }
      }
      {
        name: 'ApiMgmtSubnet'
        properties: {
          addressPrefix: '10.1.4.0/24'
          delegations: []
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', 'apim-subnet-nsg-${suffix}')
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}

output vnet object = {
  subnetRefs: vnet.properties.subnets
  vnetName: vnet.name
  vnetRef: vnet.id
}
