param tags object
param suffix string

var vnetName = 'spoke-vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'WorkloadSubnet'
        properties: {
          addressPrefix: '10.2.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', 'spoke-to-hub-rt-${suffix}')
          }
        }
      }
      {
        name: 'DataSubnet'
        properties: {
          addressPrefix: '10.2.2.0/24'
          delegations: [
            {
              name: 'mySqlFlexServerDelegation'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', 'spoke-to-hub-rt-${suffix}')
          }
        }
      }
      {
        name: 'AppSvcSubnet'
        properties: {
          addressPrefix: '10.2.3.0/24'
          delegations: [
            {
              name: 'appSvcDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', 'spoke-to-hub-rt-${suffix}')
          }
        }
      }
      {
        name: 'PrivateLinkSubnet'
        properties: {
          addressPrefix: '10.2.4.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpoints: []
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', 'spoke-to-hub-rt-${suffix}')
          }
        }
      }
      {
        name: 'FuncSubnet'
        properties: {
          addressPrefix: '10.2.5.0/24'
          delegations: [
            {
              name: 'funcSubnetDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpoints: []
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', 'spoke-to-hub-rt-${suffix}')
          }
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
