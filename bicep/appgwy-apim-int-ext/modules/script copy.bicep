param location string = 'australiaeast'
param timeStamp string = utcNow()
param webAppName string

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: 'userAssignedManagedIdentity'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, userAssignedManagedIdentity.name, subscription().subscriptionId)
  scope: resourceGroup()
  properties: {
    principalId: userAssignedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: 'Reader'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'getWebAppOutboundIpAddresses'
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentity}': {}
    }
  }
  location: location
  properties: {
    azPowerShellVersion: '5.0'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'resourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'webAppName'
        secureValue: webAppName
      }
    ]
    forceUpdateTag: timeStamp
    timeout: 'PT1H'
    retentionInterval: 'P1D'
    scriptContent: '$DeploymentScriptOutputs = @{}; $ipAddresses = $(Get-AzWebApp -ResourceGroup $env:resourceGroupName -name $env:webAppName).OutboundIpAddresses; $DeploymentScriptOutputs["ipAddresses"] = $ipAddresses'
  }
}

output outboundIpAddresses array = reference('getWebAppOutboundIpAddresses').outputs.ipAddresses
