@description('deployment location')
param location string = resourceGroup().location

@description('resource tags')
param tags object

@description('custom vNet JSON')
param vNets array

@description('Kubernetes version')
param aksVersion string

@description('AKS node VM size')
param aksNodeVmSize string = 'Standard_D2_v2'

@description('AKS node count')
param aksNodeCount int = 1

@description('AKS max pod count per worker node')
param aksMaxPodCount int = 5

@description('AKS nodes SSH Key')
param sshPublicKey string = ''

@description('AKS nodes SSH Key')
param password string

@description('Array of AAD principal ObjectIds')
param aadAdminGroupObjectIds array

@description('admin user name for Linux jump box VM')
param adminUserName string

param adminUserObjectId string

var suffix = substring(uniqueString(subscription().subscriptionId, uniqueString(resourceGroup().id)), 0, 6)
var separatedAddressprefix = split(vNets[0].subnets[0].addressPrefix, '.')
var firewallPrivateIpAddress = '${separatedAddressprefix[0]}.${separatedAddressprefix[1]}.${separatedAddressprefix[2]}.4'
var workspaceName = 'wks-${suffix}'
var kvGroupType = 'vault'
var acrGroupType = 'registry'
var storGroupType = 'blob'
var amlGroupType = 'amlworkspace'

module module_nsg 'modules/nsg.bicep' = {
  name: 'module-nsg'
  params: {
    location: location
    nsgName: 'ds-vm-nsg-${suffix}'
  }
} 

// ACR
module module_acr 'modules/acr.bicep' = {
  name: 'module-acr'
  params: {
    location: location
    suffix: suffix
    tags: tags
  }
}

// Key Vault
module module_kv 'modules/key_vault.bicep' = {
  name: 'module-kv'
  params: {
    subnetId: reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value[2].id
    location: location
    adminUserObjectId: adminUserObjectId
    suffix: suffix
  }
}

// Storage
module module_stor 'modules/storage.bicep' = {
  name: 'module-stor'
  params: {
    location: location
    subnetId: reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value[2].id
    suffix: suffix
    containerName: 'default'
  }
}

// Azure Monitor Workspace
resource az_monitor_ws 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'Standalone'
    }
    retentionInDays: 30
  }
}

// UDRs
module module_udr './modules/udr.bicep' = {
  name: 'module-udr'
  params: {
    suffix: suffix
    location: location
    azureFirewallPrivateIpAddress: firewallPrivateIpAddress
  }
}

// Virtual Networks
module module_vnet './modules/vnets.bicep' = [for (item, i) in vNets: {
  name: 'module-vnet-${i}'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    location: location
    vNet: item
    tags: tags
  }
  dependsOn: [
    module_udr
    module_nsg
  ]
}]

// Virtual Network Peering
module module_peering './modules/peering.bicep' = {
  name: 'module-peering'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    vNets: vNets
    isGatewayDeployed: false
  }
  dependsOn: [
    module_vnet
  ]
}

// Bastion Host
module bastion_host './modules/bastion.bicep' = {
  name: 'bastion-host'
  params: {
    suffix: suffix
    location: location
    tags: {}
    subnetId: reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value[2].id
  }
}

// Data Science VM
module module_ds_vm 'modules/ds-vm.bicep' = {
  name: 'module-ds-vm'
  params: {
    suffix: suffix
    vmName: 'ds-vm'
    location: location
    authenticationType: 'password'
    cpu_gpu: 'CPU-16GB'
    adminPasswordOrKey: password
    adminUsername: adminUserName
    subnetId: reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value[1].id
  }
  dependsOn: [
    module_firewall
  ]
}

// Azure Firewall
module module_firewall './modules/firewall.bicep' = {
  name: 'module-firewall'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    location: location
    workspaceId: az_monitor_ws.id
    firewallSubnetRef: reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value[0].id
    sourceAddressRangePrefixes: union(reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value, reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value)
  }
}

// AKS
module module_aks './modules/aks.bicep' = {
  name: 'module-aks'
  params: {
    suffix: suffix
    location: location
    aksVersion: aksVersion
    aksSubnetRef: reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value[0].id
    aksNodeVMSize: aksNodeVmSize
    aksNodeCount: aksNodeCount
    maxPods: aksMaxPodCount
    aadAdminGroupObjectIdList: aadAdminGroupObjectIds
    workspaceRef: az_monitor_ws.id
  }
  dependsOn: [
    module_firewall
  ]
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'app-insights-${suffix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// Azure Machine Learning Workspace
module module_aml_ws 'modules/aml.bicep' = {
  name: 'module_aml_ws'
  params: {
    applicationInsightsId: appInsights.id
    containerRegistryId: module_acr.outputs.registryResourceId
    keyVaultId: module_kv.outputs.keyVaultId
    location: location
    storageId: module_stor.outputs.storageAccountId
    suffix: suffix
  }
}

// AML Compute
module module_aml_compute 'modules/aml-compute.bicep' = {
  name: 'module-aml-compute'
  params: {
    location: location
    subnetId: reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value[2].id
    computeName: 'aml-compute'
    suffix: suffix
    objectId: adminUserObjectId
    workspaceName: module_aml_ws.outputs.amlWorkspaceName
  }
}

// Private DNS zones & Private Link Endpoints
// TODO - find Azure Batch egress dns names
// Todo - add acrPull role to AKS cluster & disable Admin access
// TODO - add A records for <acrname> & <acrname>.<location>.data to privatelink.azurecr.io + bLob & file private endpoints

module module_aml_private_link './modules/private_link.bicep' = {
  name: 'module-aml-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.MachineLearningServices/workspaces'
    resourceName: module_aml_ws.outputs.amlWorkspaceName
    groupType: amlGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.subnetRefs.value[2].id
  }
  dependsOn: [
    module_vnet
  ]
}

module module_aml_notebook_private_dns_zone './modules/private_dns_zone.bicep' = {
  name: 'module-aml-notebook-private-dns-zone'
  params: {
    privateDnsZoneName: 'privatelink.notebooks.azure.net'
  }
}

module module_aml_api_private_dns_zone './modules/private_dns_zone.bicep' = {
  name: 'module-aml-private-dns-zone'
  params: {
    privateDnsZoneName: 'privatelink.api.azureml.ms'
  }
}

module private_dns_zone_group 'modules/private_dns_zone_group.bicep' = {
  name: 'module_private_dns_zone_group'
  params: {
    privateEndpointName: module_aml_private_link.outputs.privateEndpointName
    zoneConfigs: [
      {
        name: module_aml_api_private_dns_zone.outputs.dnsZoneName
        properties: {
          privateDnsZoneId: module_aml_api_private_dns_zone.outputs.dnsZoneId
        }
      }
      {
        name: module_aml_notebook_private_dns_zone.outputs.dnsZoneName
        properties: {
          privateDnsZoneId: module_aml_notebook_private_dns_zone.outputs.dnsZoneId
        }
      }
    ]
  }
}

module module_hub_aml_api_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-hub-aml-api-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.api.azureml.ms'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetName.value
  }
}

module module_spoke_aml_api_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-spoke-aml-api-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.api.azureml.ms'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetName.value
  }
}

module module_hub_aml_notebook_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-hub-aml-notebook-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.notebooks.azure.net'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetName.value
  }
}

module module_spoke_aml_notebook_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-spoke-aml-notebook-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.notebooks.azure.net'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetName.value
  }
}

module module_kv_private_link './modules/private_link.bicep' = {
  name: 'module-kv-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.KeyVault/vaults'
    resourceName: module_kv.outputs.keyVaultName
    groupType: kvGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.subnetRefs.value[2].id
  }
  dependsOn: [
    module_vnet
  ]
}

module module_kv_private_dns_zone './modules/private_dns_zone.bicep' = {
  name: 'module-kv-private-dns-zone'
  params: {
    privateDnsZoneName: 'privatelink.vaultcore.azure.net'
  }
}

module module_hub_kv_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-kv-hub-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.vaultcore.azure.net'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetName.value
  }
}

module module_spoke_kv_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-kv-spoke-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.vaultcore.azure.net'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetName.value
  }
}

module module_acr_private_link './modules/private_link.bicep' = {
  name: 'module-acr-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.ContainerRegistry/registries'
    resourceName: module_acr.outputs.registryName
    groupType: acrGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.subnetRefs.value[2].id
  }
  dependsOn: [
    module_vnet
  ]
}

module module_acr_private_dns_zone './modules/private_dns_zone.bicep' = {
  name: 'module-acr-private-dns-zone'
  params: {
    privateDnsZoneName: 'privatelink.azurecr.io'
  }
}

module module_hub_acr_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-acr-hub-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.azurecr.io'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetName.value
  }
}

module module_spoke_acr_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-acr-spoke-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.azurecr.io'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetName.value
  }
}

module module_stor_private_link './modules/private_link.bicep' = {
  name: 'module-stor-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.Storage/storageAccounts'
    resourceName: module_stor.outputs.storageAccountName
    groupType: storGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.subnetRefs.value[2].id
  }
  dependsOn: [
    module_vnet
  ]
}

module module_blob_private_dns_zone './modules/private_dns_zone.bicep' = {
  name: 'module-blob-private-dns-zone'
  params: {
    privateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
  }
}

module module_file_private_dns_zone './modules/private_dns_zone.bicep' = {
  name: 'module-file-private-dns-zone'
  params: {
    privateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
  }
}

module module_hub_blob_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-blob-hub-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetName.value
  }
}

module module_spoke_blob_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-blob-spoke-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetName.value
  }
}

module module_hub_file_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-file-hub-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetName.value
  }
}

module module_spoke_file_private_dns_zone_link './modules/private_dns_zone_link.bicep' = {
  name: 'module-file-spoke-private-dns-zone-link'
  params: {
    privateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
    vnetRef: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetRef.value
    vnetName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetName.value
  }
}

output firewallPublicIpAddress string = module_firewall.outputs.firewallPublicIpAddress
output aksClusterName string = module_aks.outputs.aksClusterName
output aksClusterPrivateDnsHostName string = module_aks.outputs.aksControlPlanePrivateFQDN
output acrName string = module_acr.outputs.registryName
output acrServer string = module_acr.outputs.registryServer
output acrId string = module_acr.outputs.registryResourceId
