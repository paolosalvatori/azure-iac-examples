param location string
param prefix string
param imageNameAndTag string
param containerPort string
param acrName string

var affix = substring(uniqueString(resourceGroup().id), 0, 6)
var aspName = '${prefix}-asp-${affix}'
var appName = '${prefix}-app-${affix}'
var containerImageName = 'DOCKER|${existingAcr.properties.loginServer}/${imageNameAndTag}'
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource existingAcr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

resource asp 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: aspName
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource app 'Microsoft.Web/sites@2021-02-01' = {
  name: appName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: asp.id
    reserved: true
    isXenon: false
    hyperV: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: containerImageName
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    httpsOnly: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource appConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: app
  name: 'web'
  properties: {
    appSettings: [
      {
        name: 'WEBSITES_PORT'
        value: containerPort
      }
    ]
    numberOfWorkers: 1
    linuxFxVersion: containerImageName
    acrUseManagedIdentityCreds: true
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    loadBalancing: 'LeastRequests'
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.0'
    ftpsState: 'AllAllowed'
  }
}

resource appServiceAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: existingAcr
  name: guid(existingAcr.id, app.id, acrPullRoleDefinitionId)
  properties: {
    principalId: app.identity.principalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

output appName string = app.name
