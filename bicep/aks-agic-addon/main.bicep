@ allowed([
'australiaeast'
'australiasoutheast'
])
param location string
param adminGroupObjectID string
param tags object
param prefix string
param aksVersion string = '1.19.9'
param vmSku string = 'Standard_F8s_v2'
param addressPrefix string
param subnets array
param sshPublicKey string

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    prefix: prefix
    tags: tags
    location: location
    name: 'wks'
    retentionInDays: 30
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    prefix: prefix
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module acr './modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    prefix: prefix
    tags: tags
  }
}

module applicationGateway './modules/appGwy.bicep' = {
  name: 'applicationGatewayDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    applicationGatewaySKU: 'WAF_v2'
    applicationGatewaySubnetId: vnet.outputs.subnets[2].id
    prefix: prefix
    tags: tags
  }
}

module aks './modules/aks.bicep' = {
  name: 'aksDeploy'
  dependsOn: [
    vnet
    wks
    applicationGateway
  ]
  params: {
    prefix: prefix
    aksDnsPrefix: prefix
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksDockerBridgeCIDR: '172.17.0.1/16'
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksServiceCIDR: '10.100.0.0/16'
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    aksVersion: aksVersion
    enableAutoScaling: true
    enableHttpApplicationRouting: false
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: 'localadmin'
    sshPublicKey: sshPublicKey
    applicationGatewaySubnetAddressPrefix: vnet.outputs.subnets[2].properties.addressPrefix
    applicationGatewaySubnetName: subnets[2].name
    applicationGatewayId: applicationGateway.outputs.applicationGatewayId
    adminGroupObjectID: adminGroupObjectID
    addOns: {
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: applicationGateway.outputs.applicationGatewayId
          applicationGatewayWatchNamespace: 'project1,project2,default'
        }
        identity: {
          clientId: applicationGateway.outputs.managedIdentityClientId
          objectId: applicationGateway.outputs.managedIdentityPrincipalId
          resourceId: applicationGateway.outputs.managedIdentityId
        }
      }
      httpApplicationRouting: {
        enabled: false
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: wks.outputs.workspaceId
        }
      }
    }
  }
}

/* resource appGwContributorRoleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(concat(resourceGroup().id, applicationGateway.name, applicationGateway.name))
  properties: {
    roleDefinitionId: contributorRoleId
    principalId: reference(aksClusterId, '2020-12-01', 'Full').properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
    scope: resourceGroup().id
  }
  dependsOn: [
    aksClusterId
    applicationGatewayId
  ]
}
 */
