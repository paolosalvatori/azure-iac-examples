param location string = resourceGroup().location

var affix = substring(uniqueString(resourceGroup().id), 0, 6)
var vnetName = 'vnet-${affix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
      {
        name: 'vnet-integration-subnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
          delegations: [
            {
              name: 'app-server-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'private-link-subnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
        }
      }
    ]
  }
}

output gatewaySubnetId string = vnet.properties.subnets[0].id
output vnetIntegrationSubnetId string = vnet.properties.subnets[1].id
output privateLinkSubnetId string = vnet.properties.subnets[2].id
