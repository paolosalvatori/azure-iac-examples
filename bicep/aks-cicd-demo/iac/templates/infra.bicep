param tags object
param location string
param vNets array

@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

param networkResourceGroupName string = '${environment}-network-rg'
param monitorResourceGroupName string = '${environment}-monitor-rg'
param workloadResourceGroupName string = '${environment}-workload-rg'

targetScope = 'subscription'

resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: networkResourceGroupName
}

resource monitorResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: monitorResourceGroupName
}

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: workloadResourceGroupName
}

// Azure Monitor Workspace
module azMonitorModule '../modules/azmon.bicep' = {
  scope: resourceGroup(monitorResourceGroup.name)
  name: 'modules-azmon'
  params: {
    location: location
  }
}

// Virtual Networks
module vNetsModule '../modules/vnets.bicep' = [for (item, i) in vNets: {
  scope: resourceGroup(networkResourceGroup.name)
  name: 'module-vnet-${i}'
  params: {
    location: location
    vNet: item
    tags: tags
  }
}]

// Virtual Network Peering
module peeringModule '../modules/peering.bicep' = {
  scope: resourceGroup(networkResourceGroup.name)
  name: 'module-peering'
  params: {
    vNets: vNets
    isGatewayDeployed: false
  }
  dependsOn: [
    vNetsModule
  ]
}

// Azure Container Registry
module acr '../modules/acr.bicep' = {
  scope: resourceGroup(workloadResourceGroupName)
  name: 'module-acr'
  params: {
    location: location
    tags: tags
  }
}

output acrName string = acr.outputs.registryName
output hubVnetRef string = vNetsModule[0].outputs.vnetRef
output hubVnetName string = vNetsModule[0].outputs.vnetName
output spokeVnetRef string = vNetsModule[1].outputs.vnetRef
output spokeVnetName string = vNetsModule[1].outputs.vnetName
output hubVnetSubnets array = vNetsModule[0].outputs.subnetRefs
output spokeVnetSubnets array = vNetsModule[1].outputs.subnetRefs
