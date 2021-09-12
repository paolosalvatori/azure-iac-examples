param vnetAddressPrefix string
param subnets array
param vnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: subnets
  }
}

output subnetList array = [for (subnet, i) in subnets: {
  name: virtualNetwork.properties.subnets[i].name
  id: virtualNetwork.properties.subnets[i].id
}]
