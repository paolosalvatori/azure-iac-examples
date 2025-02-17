param vnetId string
param appSvcSubnetId string
param privateLinkSubnetId string
param dockerRegistryUrl string
param acrUserName string
param acrPassword string
param containerName string

param tags object = {
  costcenter: '1234567890'
  environment: 'dev'
}

@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'

var suffix = uniqueString(resourceGroup().id)
var serverFarmName = 'app-svc-${suffix}'
var siteName = 'my-app-${suffix}'
var storageName = 'stor${suffix}'
var storagePrivateDNSZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var appSvcPrivateDNSZoneName = 'azurewebsites.windows.net'

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageName
  tags: tags
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    networkAcls: {
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-12-01' = {
  kind: 'linux'
  location: resourceGroup().location
  name: serverFarmName
  sku: {
    name: skuName
    tier: 'PremiumV2'
    size: skuName
    family: skuName
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: resourceGroup().location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerName}'
    }
  }
}

resource webAppAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${webApp.name}/appsettings'
  properties: {
    'WEBSITE_DNS_SERVER': '168.63.129.16'
    'WEBSITE_VNET_ROUTE_ALL': '1'
    'WEBSITES_ENABLE_APP_SERVICE_STORAGE': false
    'DOCKER_REGISTRY_SERVER_URL': dockerRegistryUrl
    'DOCKER_REGISTRY_SERVER_USERNAME': acrUserName
    'DOCKER_REGISTRY_SERVER_PASSWORD': acrPassword
    'WEBSITE_PULL_IMAGE_OVER_VNET': true
  }
}

resource webAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${webApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: appSvcSubnetId
  }
}

resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  tags: tags
  name: 'blobPrivateEndpoint'
  properties: {
    subnet: {
      id: privateLinkSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'blobStorageConnection'
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storage.id
        }
      }
    ]
  }
}

resource appSvcPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  tags: tags
  name: 'appSvcPrivateEndpoint'
  properties: {
    subnet: {
      id: privateLinkSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'appSvcConnection'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource blobPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: storagePrivateDNSZoneName
  properties: {}
}

resource virtualNetworkStorageDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateEndpointDnsZone.name}/${blobPrivateEndpointDnsZone.name}-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource appSvcPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: appSvcPrivateDNSZoneName
  properties: {}
}

resource virtualNetworkAppSvcDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appSvcPrivateEndpointDnsZone.name}/${appSvcPrivateEndpointDnsZone.name}-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource appSvcPrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${appSvcPrivateEndpoint.name}/dnsGroup1'
  dependsOn: [
    appSvcPrivateEndpointDnsZone
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: appSvcPrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

resource blobStoragePrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${blobPrivateEndpoint.name}/dnsGroup2'
  dependsOn: [
    blobPrivateEndpointDnsZone
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: blobPrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

output storageDnsZoneId string = blobPrivateEndpointDnsZone.id
output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
output webAppPrivateEndpointIpAddress string = appSvcPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
