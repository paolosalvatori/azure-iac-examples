param name string
param region1 string = 'eastus'
param region2 string = 'westus'
param containerPort string = '8000'
param imageNameAndTag string
param dbAdminUserName string
param dbAdminPassword string
param dbSizeGB int = 32

/* param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

var frontDoorSkuName = 'Premium_AzureFrontDoor' // Private Link origins require the premium SKU.

var region1Data = {
  originHostName: region1AppModule.outputs.hostname
  privateEndpointResourceId: region1AppModule.outputs.privateEndpointId
  privateEndpointLocations: region1AppModule.outputs.privateEndpointLocation
  privateLinkResourceType: 'sites'
}

var region2Data = {
  originHostName: region2AppModule.outputs.hostname
  privateEndpointResourceId: region2AppModule.outputs.privateEndpointId
  privateEndpointLocations: region2AppModule.outputs.privateEndpointLocation
  privateLinkResourceType: 'sites'
}

var regionData = [
  region1Data
  region2Data
] */

module acrModule 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: region1
    name: name
  }
}

module region1VnetModule 'modules/vnet.bicep' = {
  name: '${region1}-vnet-deployment'
  params: {
    location: region1
    name: '${name}-${region1}-vnet'
    vnetAddressPrefix: '10.1.0.0/16'
    gatewaySubnetPrefix: '10.1.0.0/24'
    integrationSubnetAddressPrefix: '10.1.1.0/24'
    privateLinkSubnetAddressPrefix: '10.1.2.0/24'
    dbSubnetAddressPrefix: '10.1.3.0/24'
  }
}

module region2VnetModule 'modules/vnet.bicep' = {
  name: '${region2}-vnet-deployment'
  params: {
    location: region2
    name: '${name}-${region2}-vnet'
    vnetAddressPrefix: '10.2.0.0/16'
    gatewaySubnetPrefix: '10.2.0.0/24'
    integrationSubnetAddressPrefix: '10.2.1.0/24'
    privateLinkSubnetAddressPrefix: '10.2.2.0/24'
    dbSubnetAddressPrefix: '10.2.3.0/24'
  }
}

module region1ToRegion2Peer 'modules/peering.bicep' = {
  name: '${region1}-to-${region2}-peer'
  params: {
    localVnetName: region1VnetModule.outputs.vnetName
    remoteVnetName: region2VnetModule.outputs.vnetName
    remoteVnetId: region2VnetModule.outputs.vnetId
  }
}

module region2ToRegion1Peer 'modules/peering.bicep' = {
  name: '${region2}-to-${region1}-peer'
  params: {
    localVnetName: region2VnetModule.outputs.vnetName
    remoteVnetName: region1VnetModule.outputs.vnetName
    remoteVnetId: region1VnetModule.outputs.vnetId
  }
}

resource region1PostGreSQLPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${region1}.postgres.database.azure.com'
  location: 'global'
}

resource region2PostGreSQLPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${region2}.postgres.database.azure.com'
  location: 'global'
}

resource region1ToRegion1PostGreSQLPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${region1}-to-${region1}-vnet-link'
  location: 'global'
  parent: region1PostGreSQLPrivateDnsZone
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: region1VnetModule.outputs.vnetId
    }
  }
}

resource region2ToRegion2PostGreSQLPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${region2}-to-${region2}-vnet-link'
  location: 'global'
  parent: region2PostGreSQLPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: region2VnetModule.outputs.vnetId
    }
  }
}

resource region1ToRegion2PostGreSQLPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${region1}-to-${region2}-vnet-link'
  location: 'global'
  parent: region1PostGreSQLPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: region2VnetModule.outputs.vnetId
    }
  }
}

resource region2ToRegion1PostGreSQLPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${region2}-to-${region1}-vnet-link'
  location: 'global'
  parent: region2PostGreSQLPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: region1VnetModule.outputs.vnetId
    }
  }
}

module region1PostGreSQLModule './modules/postgesql-flex.bicep' = {
  dependsOn: [
    region1ToRegion1PostGreSQLPrivateDnsZoneLink
    region2ToRegion2PostGreSQLPrivateDnsZoneLink
    region1ToRegion2PostGreSQLPrivateDnsZoneLink
    region2ToRegion1PostGreSQLPrivateDnsZoneLink
  ]
  name: '${region1}-postgresql'
  params: {
    adminLoginName: dbAdminUserName
    adminPassword: dbAdminPassword
    postGreSQLDbName: 'testdb'
    storageSizeGB: dbSizeGB
    dnsZoneId: region1PostGreSQLPrivateDnsZone.id
    location: region1
    name: region1
    subnetId: region1VnetModule.outputs.dbSubnetId
  }
}

module region2PpostGreSQLModule './modules/postgesql-flex.bicep' = {
  dependsOn: [
    region1ToRegion1PostGreSQLPrivateDnsZoneLink
    region2ToRegion2PostGreSQLPrivateDnsZoneLink
    region1ToRegion2PostGreSQLPrivateDnsZoneLink
    region2ToRegion1PostGreSQLPrivateDnsZoneLink
  ]
  name: '${region2}-postgresql'
  params: {
    adminLoginName: dbAdminUserName
    adminPassword: dbAdminPassword
    postGreSQLDbName: 'testdb'
    storageSizeGB: dbSizeGB
    dnsZoneId: region2PostGreSQLPrivateDnsZone.id
    location: region2
    name: region2
    subnetId: region2VnetModule.outputs.dbSubnetId
  }
}

module region1AppModule 'modules/app.bicep' = {
  name: '${region1}-app-deployment'
  params: {
    location: region1
    name: '${name}-${region1}'
    acrName: acrModule.outputs.acrName
    containerPort: containerPort
    imageNameAndTag: imageNameAndTag
    vnetIntegrationSubnetId: region1VnetModule.outputs.integrationSubnetId
  }
}

module region2AppModule 'modules/app.bicep' = {
  name: '${region2}-app-deployment'
  params: {
    location: region2
    name: '${name}-${region2}'
    acrName: acrModule.outputs.acrName
    containerPort: containerPort
    imageNameAndTag: imageNameAndTag
    vnetIntegrationSubnetId: region2VnetModule.outputs.integrationSubnetId
  }
}
