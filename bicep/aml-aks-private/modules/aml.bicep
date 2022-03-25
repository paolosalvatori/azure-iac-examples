param location string
param suffix string
param applicationInsightsId string
param containerRegistryId string
param keyVaultId string
param storageId string

resource aml_ws 'Microsoft.MachineLearningServices/workspaces@2022-01-01-preview' = {
  name: 'aml-ws-${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    friendlyName: 'secure-aml-workspace'
    keyVault: keyVaultId
    primaryUserAssignedIdentity: ''
    publicNetworkAccess: 'Disabled'
    storageAccount: storageId
    description: 'secure aml workspace'
    allowPublicAccessWhenBehindVnet: false
    hbiWorkspace: true
/* encryption: {
      keyVaultProperties: {
        keyVaultArmId: module_kv.outputs.keyVaultId
        keyIdentifier: ''
      }
      status: 'Enabled'
      cosmosDbResourceId: ''
      searchAccountResourceId: ''
      storageAccountResourceId: module_stor.outputs.storageAccountId
    } */
  }
}

output amlWorkspaceName string = aml_ws.name
output amlWorkspaceId string = aml_ws.id
