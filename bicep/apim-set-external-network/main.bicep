param location string = 'australiasoutheast'
param vnetName string = 'apim-pb-vnet'
param subnetName string = 'apim-subnet'
param publicIpName string = 'apim-pip'
param subnetAddressPrefix string = '10.0.0.0/24'
param updateApim bool = false
param apimProperties object = {
  name: 'apim-pb'
  sku: {
    name: 'Premium'
    capacity: 1
  }
  publisherEmail: 'cbellee@microsoft.com'
  publisherName: 'KainiIndustries'
}
param nsgName string = 'apim-nsg'
param domainLabelPrefix string = 'apim-pb'
param tags object = {
  'environment': 'uat'
  'costcentre': '1234567890'
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: location
  name: publicIpName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: domainLabelPrefix
    }
  }
  tags: tags
}

module apimNsgModule 'nsg.bicep' = {
  name: 'apimNsgDeployment'
  params: {
    location: location
    nsgName: nsgName
    tags: tags
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: apimNsgModule.outputs.nsgId
    }
  }
}

resource apim 'Microsoft.ApiManagement/service@2020-12-01' = if (updateApim == true) {
  name: apimProperties.name
  location: location
  tags: tags
  sku: apimProperties.sku
  properties: {
    publisherEmail: apimProperties.publisherEmail
    publisherName: apimProperties.publisherName
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: subnet.id
    }
  }
}
