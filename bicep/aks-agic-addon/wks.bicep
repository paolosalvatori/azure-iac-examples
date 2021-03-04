param name string
param location string
param suffix string
param tags object
param retentionInDays int {
  default: 30
}

var workspaceName = '${name}-${uniqueString(resourceGroup().id)}'

resource azureMonitorWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  location: location
  name: workspaceName
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: 'Standard'
    }
  }
}

output workspaceId string = azureMonitorWorkspace.id 