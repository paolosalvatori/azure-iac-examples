param name string
param region1 string
param containerPort string
param imageNameAndTag string
param dbAdminUserName string

@secure()
param dbAdminPassword string
param dbSizeGB int = 32
param adminUserObjectId string

var affix = substring(uniqueString(resourceGroup().id), 0, 6)

// deploy Azure Container Registry
module acrModule 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: region1
    name: name
  }
}

// Deploy vnets
module vnetModule 'modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: region1
    name: '${name}-vnet'
    vnetAddressPrefix: '10.1.0.0/16'
    gatewaySubnetPrefix: '10.1.0.0/24'
    integrationSubnetAddressPrefix: '10.1.1.0/24'
    privateLinkSubnetAddressPrefix: '10.1.2.0/24'
    dbSubnetAddressPrefix: '10.1.3.0/24'
  }
}

// create private DNS zone
resource postGreSQLPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'testdb.postgres.database.azure.com'
  location: 'global'
}

// link DNS zones to vnets
resource postGreSQLPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'private-dns-zone-vnet-link'
  location: 'global'
  parent: postGreSQLPrivateDnsZone
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetModule.outputs.vnetId
    }
  }
}

// Deploy PostGreSQL server & database
module postGreSQLModule './modules/postgesql-flex.bicep' = {
  dependsOn: [
    postGreSQLPrivateDnsZoneLink
  ]
  name: 'postgresql'
  params: {
    adminLoginName: dbAdminUserName
    adminPassword: dbAdminPassword
    postGreSQLDbName: 'testdb'
    storageSizeGB: dbSizeGB
    dnsZoneId: postGreSQLPrivateDnsZone.id
    location: region1
    name: region1
    subnetId: vnetModule.outputs.dbSubnetId
  }
}

// Deploy Key vault to store DB connection strings 
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  location: region1
  name: '${name}-kv-${affix}'
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: false
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: adminUserObjectId
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

// Deploy secerts to key vault
resource dbSecret1 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '${keyVault.name}/db-cxn'
  properties: {
    attributes: {
      enabled: true
    }
    value: postGreSQLModule.outputs.postGreSQLCxn
  }
}

// create App service plans and apps per region
module region1AppModule 'modules/app.bicep' = {
  name: '${region1}-app-deployment'
  params: {
    location: region1
    name: '${name}-${region1}'
    acrName: acrModule.outputs.acrName
    containerPort: containerPort
    imageNameAndTag: imageNameAndTag
    vnetIntegrationSubnetId: vnetModule.outputs.integrationSubnetId
    keyVaultName: keyVault.name
    secretUri: dbSecret1.properties.secretUri
  }
}


// output app serice URL
output region1AppUrl string = '${region1AppModule.outputs.hostname}/info'
