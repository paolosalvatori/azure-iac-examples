param name string
param location string
param prefix string
param tags object
param retentionInDays int = 30

var workspaceName = '${prefix}-${uniqueString(resourceGroup().id)}-wks'

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
