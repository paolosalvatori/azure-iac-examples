param location string
param storageSku string = 'Standard_LRS'
param storageKind string = 'StorageV2'
param containerName string = 'default'
param subnetId string
param suffix string

var storageAccountName = 'stor${suffix}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2018-07-01' = {
  name: storageAccountName
  sku: {
    name: storageSku
  }
  kind: storageKind
  location: location
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetId
        }
      ]
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  dependsOn: []
}

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2018-07-01' = {
  name: '${storageAccountName}/default/${containerName}'
  dependsOn: [
    storageAccount
  ]
}

output storageAccountName string = storageAccountName
output storageContainerUri string = '${storageAccount.properties.primaryEndpoints.blob}containerName}'
output containerName string = containerName
