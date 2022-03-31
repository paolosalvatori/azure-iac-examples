param location string
param applicationInsightsId string
param containerRegistryId string
param keyVaultId string
param storageId string
param amlComputeName string
param workspaceName string
param aksClusterId string
param loadBalancerSubnetName string
param aksClusterFqdn string

resource aml_ws 'Microsoft.MachineLearningServices/workspaces@2022-01-01-preview' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    imageBuildCompute: amlComputeName
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

resource amlAksCompute 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  name: 'aks-inference'
  location: location
  parent: aml_ws
  properties: {
    // computeLocation: location
    description: 'aks inference cluster'
    // disableLocalAuth: false
    resourceId: aksClusterId
    computeType: 'AKS'
/*     properties: {
      loadBalancerType: 'InternalLoadBalancer'
      loadBalancerSubnet: loadBalancerSubnetName
    } */
  }
}

output amlWorkspaceName string = aml_ws.name
output amlWorkspaceId string = aml_ws.id
