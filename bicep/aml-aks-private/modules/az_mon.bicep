param location string
param workspaceName string
param sku string

resource az_monitor_ws 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: 30
  }
}

output workspaceId string = az_monitor_ws.id
output workspaceName string = az_monitor_ws.name
