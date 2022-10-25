param location string

var suffix = uniqueString(resourceGroup().id)
var workspaceName = 'ws-${suffix}'

resource azureMonitorWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output workspaceId string = azureMonitorWorkspace.id
