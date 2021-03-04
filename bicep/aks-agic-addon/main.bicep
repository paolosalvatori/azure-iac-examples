param location string {
  allowed: [
    'australiaeast'
    'australiasoutheast'
  ]
}

param tags object

param prefix string

param suffix string

param aksVersion string {
  default: '1.19.6'
}

param vmSKU string

param addressPrefix string

param subnets array

module wks 'wks.bicep' = {
  name: 'wksDeploy'
  params: {
    suffix: suffix
    tags: tags
    location: location
    name: 'wks'
    retentionInDays: 30
  }
}

module vnet 'vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    suffix: suffix
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module acr 'acr.bicep' = {
  name: 'acrDeploy'
  params: {
    suffix: suffix
    tags: tags
  }
}

module appGwy 'appGwy.bicep' = {
  name: 'appGwyDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    appGwySKU: 'WAF_v2'
    appGwySubnetId: vnet.outputs.subnets[0].id
    suffix: suffix
    tags: tags
  }
}

module aks 'aks.bicep' = {
  name: 'aksDeploy'
  dependsOn: [
    vnet
    wks
    appGwy
  ]
  params: {
    suffix: suffix
    aksDnsPrefix: prefix
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksDockerBridgeCIDR: '172.17.0.1/16'
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 3
    aksNodeVMSize: vmSKU
    aksServiceCIDR: '10.100.0.0/16'
    aksSubnetId:  vnet.outputs.subnets[1].id
    aksVersion: aksVersion
    enableAutoScaling: true
    enableHttpApplicationRouting: false
    maxPods: 30
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    appGwySubnetAddressPrefix: vnet.outputs.subnets[0].properties.addressPrefix
    appGwySubnetName: subnets[0].name
    appGwyId: appGwy.outputs.applicationGatewayId
    addOns: {
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      ingressAPplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appGwy.outputs.applicationGatewayId
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