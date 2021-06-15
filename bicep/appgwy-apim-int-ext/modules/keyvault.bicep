param keyVaultUserObjectId string
param name string
param tenantId string
param location string

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: name
  location: location
  tags: {
    displayName: name
  }
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    createMode: 'default'
    tenantId: tenantId
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: keyVaultUserObjectId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'import'
          ]
          secrets: [
            'get'
            'list'
            'set'
          ]
          certificates: [
            'get'
            'list'
            'create'
            'import'
            'update'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output keyVault object = keyVault
