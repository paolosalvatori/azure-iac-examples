param aksDnsPrefix string {
  metadata: {
    description: 'Optional DNS prefix to use with hosted Kubernetes API server FQDN.'
  }
  default: 'aks'
}
param aksAgentOsDiskSizeGB int {
  minValue: 30
  maxValue: 1023
  metadata: {
    description: 'Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 30 to 1023.'
  }
  default: 250
}

param addOns object

param appGwyId string

param appGwySubnetName string

param appGwySubnetAddressPrefix string

param tags object

param maxPods int {
  minValue: 10
  maxValue: 120
  default: 50
}
param networkPlugin string {
  allowed: [
    'azure'
    'kubenet'
  ]
  default: 'azure'
}
param enablePodSecurityPolicy bool = false
param enableHttpApplicationRouting bool = false
param aksNodeCount int {
  minValue: 1
  maxValue: 50
  metadata: {
    description: 'The default number of agent nodes for the cluster.'
  }
  default: 3
}
param enableAutoScaling bool = true
param aksMinNodeCount int {
  minValue: 1
  maxValue: 50
  metadata: {
    description: 'The minimum number of agent nodes for the cluster.'
  }
  default: 1
}
param aksMaxNodeCount int {
  minValue: 1
  maxValue: 50
  metadata: {
    description: 'The maximum number of agent nodes for the cluster.'
  }
  default: 10
}
param aksNodeVMSize string {
  metadata: {
    description: 'The size of the Virtual Machine.'
  }
  default: 'Standard_D4s_v3'
}
param aksVersion string {
  metadata: {
    description: 'The version of Kubernetes.'
  }
  default: '1.19.6'
}
param aksSubnetId string
param suffix string
param aksServiceCIDR string {
  metadata: {
    description: 'A CIDR notation IP range from which to assign service cluster IPs.'
  }
  default: '10.100.0.0/16'
}
param aksDnsServiceIP string {
  metadata: {
    description: 'Containers DNS server IP address.'
  }
  default: '10.100.0.10'
}
param aksDockerBridgeCIDR string {
  metadata: {
    description: 'A CIDR notation IP for Docker bridge.'
  }
  default: '172.17.0.1/16'
}
param aksEnableRBAC bool {
  metadata: {
    description: 'Enable RBAC on the AKS cluster.'
  }
  default: true
}

var storageAccountName = 'stor${substring(uniqueString(resourceGroup().id), 0, 10)}'
//var identityName = 'appgwContrIdentity-${suffix}'
var aksClusterName = '${suffix}-aks'
//var identityId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', identityName)
var aksClusterId = aksClusterName_resource.id

resource storageAccount 'Microsoft.Storage/storageAccounts@2018-07-01' = {
  name: storageAccountName
  location: resourceGroup().location
  tags: {
    displayName: storageAccountName
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource aksClusterName_resource 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: aksClusterName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: aksVersion
    enableRBAC: aksEnableRBAC
    enablePodSecurityPolicy: enablePodSecurityPolicy
    dnsPrefix: aksDnsPrefix
    addonProfiles: addOns
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        count: 1
        enableAutoScaling: true
        minCount: aksMinNodeCount
        maxCount: aksMaxNodeCount
        maxPods: maxPods
        osDiskSizeGB: aksAgentOsDiskSizeGB
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetId
        tags: tags
        vmSize: aksNodeVMSize
        osDiskType: 'Ephemeral'
      }
      {
        name: 'user1'
        mode: 'User'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        osDiskSizeGB: aksAgentOsDiskSizeGB
        count: aksNodeCount
        minCount: aksMinNodeCount
        maxCount: aksMaxNodeCount
        vmSize: aksNodeVMSize
        osType: 'Linux'
        osDiskType: 'Ephemeral'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetId
        enableAutoScaling: enableAutoScaling
        maxPods: maxPods
        tags: tags
      }
    ]
    networkProfile: {
      networkPlugin: networkPlugin
      serviceCidr: aksServiceCIDR
      dnsServiceIP: aksDnsServiceIP
      dockerBridgeCidr: aksDockerBridgeCIDR
      loadBalancerSku: 'standard'
    }
  }
}

output aksName string = aksClusterName
output aksControlPlaneFQDN string = reference('Microsoft.ContainerService/managedClusters/${aksClusterName}').fqdn
// output applicationGatewayIdentityResourceId string = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', identityName)
// output applicationGatewayIdentityClientId string = reference(identityId, '2015-08-31-PREVIEW').clientId
output aksApiServerUri string = '${reference(aksClusterId, '2018-03-31').fqdn}:443'
output aksClusterName string = aksClusterName